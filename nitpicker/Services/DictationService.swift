//
//  DictationService.swift
//  nitpicker
//
//  Created on 17/12/25.
//

import Foundation
import AVFoundation
import FluidAudio

/// Service to handle audio recording and speech-to-text transcription using FluidAudio
class DictationService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcribedText = ""
    @Published var error: Error?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var asrManager: AsrManager?
    private var vadManager: VadManager?
    private var vadState: VadStreamState?
    private var audioSamples: [Float] = []
    private let sampleRate: Double = 16000.0
    private var bufferCount = 0
    private var converter: AVAudioConverter?
    private let audioProcessingQueue = DispatchQueue(label: "com.nitpicker.audioProcessing", qos: .userInitiated)
    
    // Real-time transcription properties
    private var realtimeCallback: ((String) -> Void)?
    private var streamingBuffer: [Float] = []
    private let streamingBufferSize = 48000 // 3 seconds of audio at 16kHz - optimal for context
    private let minChunkSize = 24000 // Minimum 1.5 seconds before transcribing
    private var fullAudioForContext: [Float] = [] // Keep full audio for context
    private var lastOutputLength = 0
    private var isRealtimeMode = false
    private var transcriptionQueue = DispatchQueue(label: "com.nitpicker.transcription", qos: .userInitiated)
    private var isTranscribingChunk = false
    private var lastTranscriptionTime = Date()
    private let minTranscriptionInterval: TimeInterval = 1.5 // Wait at least 1.5s between transcriptions
    
    // VAD properties
    private var isSpeaking = false
    private var speechBuffer: [Float] = [] // Buffer for current speech segment
    private var vadChunkBuffer: [Float] = [] // Buffer to accumulate chunks for VAD (256ms = 4096 samples)
    private let vadChunkSize = 4096 // VAD processes in 256ms chunks at 16kHz
    
    static let shared = DictationService()
    
    override init() {
        super.init()
    }
    
    /// Request and check microphone permissions
    func requestMicrophonePermission() async -> Bool {
        // Check current authorization status
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        print("DictationService: Current microphone permission status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("DictationService: ✅ Microphone permission already granted")
            return true
            
        case .notDetermined:
            // Request permission
            print("DictationService: 🔐 Requesting microphone permission...")
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            print("DictationService: Permission request result: \(granted ? "✅ Granted" : "❌ Denied")")
            return granted
            
        case .denied:
            print("DictationService: ❌ Microphone permission denied")
            print("DictationService: Please enable microphone access in System Settings → Privacy & Security → Microphone")
            return false
            
        case .restricted:
            print("DictationService: ⚠️ Microphone access restricted")
            return false
            
        @unknown default:
            print("DictationService: ⚠️ Unknown permission status")
            return false
        }
    }
    
    /// Initialize ASR and VAD models (downloads and loads models on first run)
    func initializeASR() async throws {
        guard asrManager == nil else { 
            print("DictationService: ASR already initialized")
            return 
        }
        
        do {
            print("DictationService: Starting ASR initialization...")
            print("DictationService: Downloading and loading models (this may take a while on first run)...")
            
            // Download and load ASR models (v3 for multilingual support)
            let models = try await AsrModels.downloadAndLoad(version: .v3)
            
            print("DictationService: Models loaded, initializing ASR manager...")
            
            // Initialize ASR manager with default config
            let manager = AsrManager(config: .default)
            try await manager.initialize(models: models)
            
            self.asrManager = manager
            print("DictationService: ✅ ASR models initialized successfully")
            
            // Initialize VAD manager
            print("DictationService: Initializing VAD...")
            let vadConfig = VadConfig(defaultThreshold: 0.5) // Balanced threshold
            let vad = try await VadManager(config: vadConfig)
            self.vadManager = vad
            print("DictationService: ✅ VAD initialized successfully")
            
        } catch {
            print("DictationService: ❌ Failed to initialize ASR/VAD - \(error)")
            print("DictationService: Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Start recording audio from the microphone
    /// - Parameter realtimeCallback: Optional callback for real-time transcription updates
    func startRecording(realtimeCallback: ((String) -> Void)? = nil) async throws {
        // First, check and request microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            print("DictationService: ❌ Cannot start recording - no microphone permission")
            throw DictationError.microphonePermissionDenied
        }
        
        // Initialize ASR if needed
        if asrManager == nil {
            try await initializeASR()
        }
        
        // Reset state
        audioSamples.removeAll()
        streamingBuffer.removeAll()
        fullAudioForContext.removeAll()
        speechBuffer.removeAll()
        vadChunkBuffer.removeAll()
        transcribedText = ""
        error = nil
        bufferCount = 0
        lastOutputLength = 0
        isTranscribingChunk = false
        lastTranscriptionTime = Date()
        isSpeaking = false
        
        // Reset VAD state
        if let vadManager = vadManager {
            vadState = await vadManager.makeStreamState()
            print("DictationService: VAD state reset")
        }
        
        // Set real-time mode
        self.realtimeCallback = realtimeCallback
        self.isRealtimeMode = realtimeCallback != nil
        
        if isRealtimeMode {
            print("DictationService: Starting in REAL-TIME mode")
        } else {
            print("DictationService: Starting in batch mode")
        }
        
        // Setup audio engine
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let input = engine.inputNode
        inputNode = input
        
        // Prepare the audio engine
        engine.prepare()
        
        // Check the input node's current status
        print("DictationService: Input node - \(input)")
        print("DictationService: Input node volume: \(input.volume)")
        
        #if os(macOS)
        // On macOS, check if there's a valid audio device
        if let audioUnit = input.audioUnit {
            print("DictationService: Input has audio unit: \(audioUnit)")
        } else {
            print("DictationService: ⚠️ WARNING: No audio unit found on input node")
        }
        #endif
        
        // Get the input format from the microphone
        let inputFormat = input.outputFormat(forBus: 0)
        
        print("DictationService: Input format - sampleRate: \(inputFormat.sampleRate), channels: \(inputFormat.channelCount)")
        
        // Validate input format
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            print("DictationService: Invalid input format")
            throw DictationError.audioFormatError
        }
        
        // Create desired format (16kHz mono Float32 for FluidAudio)
        guard let desiredFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            print("DictationService: Failed to create desired format")
            throw DictationError.audioFormatError
        }
        
        // Create converter from input format to desired format
        guard let audioConverter = AVAudioConverter(from: inputFormat, to: desiredFormat) else {
            print("DictationService: Failed to create audio converter")
            throw DictationError.audioFormatError
        }
        
        converter = audioConverter
        
        print("DictationService: Converter created - converting from \(inputFormat.sampleRate)Hz to \(desiredFormat.sampleRate)Hz")
        
        // Install tap on input node with the hardware format
        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            self.audioProcessingQueue.async {
                self.processAudioBuffer(buffer)
            }
        }
        
        // Now start the audio engine to begin capturing
        do {
            try engine.start()
            print("DictationService: Audio engine started")
        } catch {
            // Remove the tap on error
            input.removeTap(onBus: 0)
            
            // Check if this is a permission error
            let nsError = error as NSError
            if nsError.domain == NSOSStatusErrorDomain && nsError.code == -50 {
                throw DictationError.microphonePermissionDenied
            }
            print("DictationService: Failed to start audio engine - \(error)")
            throw DictationError.audioEngineInitializationFailed
        }
        
        await MainActor.run {
            self.isRecording = true
        }
        
        print("DictationService: Recording started")
    }
    
    /// Stop recording and transcribe the audio
    func stopRecording() async throws -> String {
        guard let audioEngine = audioEngine else {
            throw DictationError.noActiveRecording
        }
        
        // Stop the audio engine
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        
        await MainActor.run {
            self.isRecording = false
            self.isTranscribing = true
        }
        
        print("DictationService: Recording stopped")
        print("DictationService: Collected \(audioSamples.count) samples at 16kHz")
        print("DictationService: Duration: \(Double(audioSamples.count) / sampleRate) seconds")
        
        // Analyze audio samples
        if !audioSamples.isEmpty {
            let maxSample = audioSamples.max() ?? 0
            let minSample = audioSamples.min() ?? 0
            let avgSample = audioSamples.reduce(0, +) / Float(audioSamples.count)
            let nonZeroCount = audioSamples.filter { abs($0) > 0.0001 }.count
            
            print("DictationService: Audio analysis:")
            print("  - Min: \(minSample), Max: \(maxSample), Avg: \(avgSample)")
            print("  - Non-zero samples: \(nonZeroCount) / \(audioSamples.count) (\(Double(nonZeroCount) / Double(audioSamples.count) * 100)%)")
            
            if maxSample < 0.01 && minSample > -0.01 {
                print("DictationService: ⚠️ WARNING: Audio levels very low - this may cause empty transcription")
            }
        }
        
        // Check if we have enough audio
        guard !audioSamples.isEmpty else {
            await MainActor.run {
                self.error = DictationError.noAudioRecorded
                self.isTranscribing = false
            }
            throw DictationError.noAudioRecorded
        }
        
        // Minimum audio length check (at least 0.1 seconds)
        let minSamples = Int(sampleRate * 0.1)
        if audioSamples.count < minSamples {
            print("DictationService: Warning - very short audio (\(audioSamples.count) samples)")
        }
        
        // Transcribe the audio
        guard let asrManager = asrManager else {
            throw DictationError.asrNotInitialized
        }
        
        print("DictationService: Starting transcription...")
        
        do {
            let result = try await asrManager.transcribe(audioSamples)
            let text = result.text
            
            print("DictationService: Transcription result received")
            print("DictationService: Result type: \(type(of: result))")
            print("DictationService: Text length: \(text.count) characters")
            print("DictationService: Text: '\(text)'")
            
            // Check if result has any other useful properties
            let mirror = Mirror(reflecting: result)
            print("DictationService: Result properties:")
            for child in mirror.children {
                if let label = child.label {
                    print("  - \(label): \(child.value)")
                }
            }
            
            if text.isEmpty {
                print("DictationService: ⚠️ Warning - Transcription returned empty text")
                print("DictationService: This could mean:")
                print("  - No speech was detected in the audio")
                print("  - Audio quality was too poor")
                print("  - Models are not properly loaded")
            }
            
            await MainActor.run {
                self.transcribedText = text
                self.isTranscribing = false
            }
            
            print("DictationService: Transcription complete - '\(text)'")
            return text
        } catch {
            await MainActor.run {
                self.error = error
                self.isTranscribing = false
            }
            print("DictationService: Transcription failed - \(error)")
            throw error
        }
    }
    
    /// Process audio buffer - convert format and collect samples
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferCount += 1
        
        // Log first few buffers
        if bufferCount <= 3 {
            print("DictationService: Buffer #\(bufferCount) - frameLength: \(buffer.frameLength)")
            
            // Debug first buffer samples
            if bufferCount == 1, let channelData = buffer.floatChannelData {
                let samples = Array(UnsafeBufferPointer(start: channelData[0], count: min(10, Int(buffer.frameLength))))
                print("DictationService: First 10 sample values: \(samples)")
                let allSamples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
                let maxVal = allSamples.max() ?? 0
                let minVal = allSamples.min() ?? 0
                print("DictationService: Sample range: \(minVal) to \(maxVal)")
            }
        }
        
        guard let converter = converter else {
            print("DictationService: No converter available")
            return
        }
        
        let desiredFormat = converter.outputFormat
        
        // Calculate output buffer size
        let inputSampleRate = buffer.format.sampleRate
        let outputSampleRate = desiredFormat.sampleRate
        let ratio = outputSampleRate / inputSampleRate
        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: desiredFormat, frameCapacity: outputCapacity) else {
            print("DictationService: Failed to create converted buffer")
            return
        }
        
        var error: NSError?
        var hasProvidedBuffer = false
        
        let conversionStatus = converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            if hasProvidedBuffer {
                outStatus.pointee = .noDataNow
                return nil
            } else {
                hasProvidedBuffer = true
                outStatus.pointee = .haveData
                return buffer
            }
        }
        
        if let error = error {
            print("DictationService: Conversion error - \(error.localizedDescription)")
            return
        }
        
        if bufferCount <= 3 {
            print("DictationService: Conversion status: \(conversionStatus)")
            print("DictationService: Converted buffer frameLength: \(convertedBuffer.frameLength)")
        }
        
        // Extract Float32 samples from converted buffer
        guard let channelData = convertedBuffer.floatChannelData else {
            print("DictationService: No channel data in converted buffer")
            return
        }
        
        let frameLength = Int(convertedBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        if bufferCount <= 3 {
            let samplePreview = samples.prefix(10)
            print("DictationService: Converted samples preview: \(samplePreview)")
            let maxSample = samples.max() ?? 0
            let minSample = samples.min() ?? 0
            print("DictationService: Converted sample range: \(minSample) to \(maxSample)")
        }
        
        // Add to audio samples array (thread-safe)
        audioSamples.append(contentsOf: samples)
        
        // Real-time transcription with VAD if enabled
        if isRealtimeMode {
            // Add samples to VAD chunk buffer
            vadChunkBuffer.append(contentsOf: samples)
            
            // Process VAD in chunks of 4096 samples (256ms at 16kHz)
            while vadChunkBuffer.count >= vadChunkSize {
                let chunk = Array(vadChunkBuffer.prefix(vadChunkSize))
                vadChunkBuffer.removeFirst(vadChunkSize)
                
                // Process VAD for this chunk
                Task {
                    await self.processVADChunk(chunk)
                }
            }
        }
        
        if bufferCount <= 3 {
            print("DictationService: Converted \(buffer.frameLength) → \(frameLength) samples")
            print("DictationService: Total samples collected: \(audioSamples.count)")
        }
    }
    
    /// Process VAD chunk and trigger transcription on speech segments
    private func processVADChunk(_ chunk: [Float]) async {
        guard let vadManager = vadManager, let currentState = vadState else { return }
        
        do {
            // Process the chunk through VAD
            let result = try await vadManager.processStreamingChunk(
                chunk,
                state: currentState,
                config: .default,
                returnSeconds: true,
                timeResolution: 2
            )
            
            // Update VAD state
            vadState = result.state
            
            // Log probability for debugging
            if bufferCount <= 5 {
                print("DictationService: VAD probability: \(String(format: "%.3f", result.probability))")
            }
            
            // Handle speech events
            if let event = result.event {
                switch event.kind {
                case .speechStart:
                    print("DictationService: 🎤 Speech started at \(event.time ?? 0)s")
                    isSpeaking = true
                    speechBuffer.removeAll()
                    fullAudioForContext.removeAll()
                    lastOutputLength = 0
                    
                case .speechEnd:
                    print("DictationService: 🛑 Speech ended at \(event.time ?? 0)s")
                    isSpeaking = false
                    
                    // Transcribe the complete speech segment
                    if !speechBuffer.isEmpty && !isTranscribingChunk {
                        let bufferToTranscribe = Array(speechBuffer)
                        print("DictationService: Transcribing speech segment (\(bufferToTranscribe.count) samples, \(Double(bufferToTranscribe.count) / sampleRate)s)")
                        
                        isTranscribingChunk = true
                        Task {
                            await self.transcribeRealtimeChunk(bufferToTranscribe)
                            self.isTranscribingChunk = false
                        }
                    }
                }
            }
            
            // Accumulate audio during speech
            if isSpeaking {
                speechBuffer.append(contentsOf: chunk)
                fullAudioForContext.append(contentsOf: chunk)
                
                // Also transcribe periodically during long speech (every 3 seconds)
                let timeSinceLastTranscription = Date().timeIntervalSince(lastTranscriptionTime)
                if fullAudioForContext.count >= streamingBufferSize && 
                   timeSinceLastTranscription >= minTranscriptionInterval &&
                   !isTranscribingChunk {
                    
                    let bufferToTranscribe = Array(fullAudioForContext)
                    print("DictationService: Intermediate transcription during speech (\(bufferToTranscribe.count) samples)")
                    
                    isTranscribingChunk = true
                    lastTranscriptionTime = Date()
                    
                    Task {
                        await self.transcribeRealtimeChunk(bufferToTranscribe)
                        self.isTranscribingChunk = false
                    }
                }
            }
            
        } catch {
            print("DictationService: VAD processing error - \(error)")
        }
    }
    
    /// Transcribe a chunk of audio in real-time using cumulative context
    private func transcribeRealtimeChunk(_ samples: [Float]) async {
        guard let asrManager = asrManager else { return }
        
        do {
            let result = try await asrManager.transcribe(samples)
            let fullText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !fullText.isEmpty else { return }
            
            print("DictationService: Full transcription: '\(fullText)'")
            
            // Extract only the new portion that wasn't output before
            let newText = extractNewText(from: fullText)
            
            if !newText.isEmpty {
                print("DictationService: New portion to type: '\(newText)'")
                
                await MainActor.run {
                    self.transcribedText = fullText
                }
                
                // Call the callback with new text only
                realtimeCallback?(newText)
                
                // Update the last output length
                lastOutputLength = fullText.count
            }
            
        } catch {
            print("DictationService: Real-time transcription error - \(error)")
        }
    }
    
    /// Extract new text from full transcription based on character count
    private func extractNewText(from fullText: String) -> String {
        guard lastOutputLength < fullText.count else { return "" }
        
        // Get new characters
        let newText = String(fullText.dropFirst(lastOutputLength))
        
        // Clean up: if it starts with partial word, try to complete it
        var cleanedText = newText
        if lastOutputLength > 0 && !newText.isEmpty {
            // If the new text starts without a space, add one
            if !newText.hasPrefix(" ") && !fullText.isEmpty {
                let lastChar = fullText[fullText.index(fullText.startIndex, offsetBy: lastOutputLength - 1)]
                if lastChar != " " && lastChar != "\n" {
                    cleanedText = " " + cleanedText
                }
            }
        }
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    

    
    /// Cancel recording without transcription
    func cancelRecording() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioSamples.removeAll()
        streamingBuffer.removeAll()
        fullAudioForContext.removeAll()
        speechBuffer.removeAll()
        vadChunkBuffer.removeAll()
        realtimeCallback = nil
        isRealtimeMode = false
        lastOutputLength = 0
        isTranscribingChunk = false
        isSpeaking = false
        vadState = nil
        
        Task { @MainActor in
            isRecording = false
            isTranscribing = false
        }
        
        print("DictationService: Recording cancelled")
    }
}

// MARK: - Errors
enum DictationError: LocalizedError {
    case microphonePermissionDenied
    case audioEngineInitializationFailed
    case audioFormatError
    case noActiveRecording
    case asrNotInitialized
    case noAudioRecorded
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access denied. Please grant permission in System Settings → Privacy & Security → Microphone and enable it for Nitpicker."
        case .audioEngineInitializationFailed:
            return "Failed to initialize audio engine. Please check your microphone is connected and try again."
        case .audioFormatError:
            return "Failed to configure audio format."
        case .noActiveRecording:
            return "No active recording to stop."
        case .asrNotInitialized:
            return "Speech recognition not initialized. Please try again."
        case .noAudioRecorded:
            return "No audio was recorded. Please check your microphone is working and try speaking louder."
        }
    }
}
