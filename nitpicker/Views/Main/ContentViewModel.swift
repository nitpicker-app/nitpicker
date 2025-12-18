//
//  MainViewModel.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation
import Combine
import AppKit

class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var lastCorrection: ClippedText?
    @Published var showPermissionAlert = false
    
    private let dictationService = DictationService.shared

    func correctSelectedText() {
        // First verify accessibility permissions are granted
        let permissionManager = AccessibilityPermissionManager.shared
        if !permissionManager.hasAccessibilityPermissions {
            print("ContentViewModel: ⚠️ Cannot correct text - accessibility permissions not granted")
            permissionManager.checkAndRequestAccessibilityPermissions(showUI: true)
            return
        }
        
        guard let selectedText = ClipboardHelper.copySelectedText() else {
            return
        }
        
        isLoading = true

        Task {
            await TextCorrectionServiceFactory.current.correctGrammar(text: selectedText) { [weak self] corrected in
                print("ContentViewModel: Received corrected text from service.")
                print("ContentViewModel: Corrected text: \(String(corrected.prefix(50)))...")
                DispatchQueue.main.async {
                    self?.lastCorrection = ClippedText(originalText: selectedText, correctedText: corrected)
                    print("ContentViewModel: Replacing selected text with corrected version")
                    ClipboardHelper.replaceSelectedText(with: corrected)
                    self?.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Dictation Methods
    
    /// Start dictation and record audio with real-time transcription
    func startDictation() {
        Task {
            do {
                // Start recording with real-time callback that types as we speak
                try await dictationService.startRecording { [weak self] newText in
                    guard let self = self else { return }
                    
                    // Type the new text in real-time
                    DispatchQueue.main.async {
                        print("ContentViewModel: Typing real-time text: '\(newText)'")
                        ClipboardHelper.typeText(newText)
                    }
                }
                print("ContentViewModel: Real-time dictation started")
            } catch DictationError.microphonePermissionDenied {
                print("ContentViewModel: Failed to start dictation - microphone permission denied")
                await MainActor.run {
                    self.showMicrophonePermissionAlert()
                }
            } catch {
                print("ContentViewModel: Failed to start dictation - \(error)")
                await MainActor.run {
                    self.showErrorAlert(error: error)
                }
            }
        }
    }
    
    /// Show alert for microphone permission
    private func showMicrophonePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = "Nitpicker needs access to your microphone for voice dictation.\n\nPlease enable microphone access in:\nSystem Settings → Privacy & Security → Microphone"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Privacy & Security
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// Show generic error alert
    private func showErrorAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Dictation Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    /// Stop dictation, transcribe, and optionally correct the text
    func stopDictation() {
        Task {
            do {
                // Simply stop recording - text has already been typed in real-time
                let transcribedText = try await dictationService.stopRecording()
                print("ContentViewModel: Final transcription: \(transcribedText)")
                
                // Note: We don't apply correction here since text is already typed
                // If you want to correct the already-typed text, you would need to:
                // 1. Select all the typed text
                // 2. Apply correction
                // 3. Replace it
                
            } catch {
                print("ContentViewModel: Failed to stop dictation - \(error)")
            }
        }
    }
    
    /// Correct the transcribed text and paste it
    private func correctTranscribedText(_ text: String) async {
        guard !text.isEmpty else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        await TextCorrectionServiceFactory.current.correctGrammar(text: text) { [weak self] corrected in
            print("ContentViewModel: Corrected transcription: \(corrected)")
            DispatchQueue.main.async {
                self?.lastCorrection = ClippedText(originalText: text, correctedText: corrected)
                
                // Paste the corrected text
                ClipboardHelper.replaceSelectedText(with: corrected)
                self?.isLoading = false
            }
        }
    }
}
