//
//  ContentView.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @StateObject private var dictationService = DictationService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("Nitpicker")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView("Correcting...")
                        .controlSize(.small)
                } else if dictationService.isRecording {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Recording...")
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        Button("Stop & Transcribe") {
                            viewModel.stopDictation()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("Cancel") {
                            dictationService.cancelRecording()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else if dictationService.isTranscribing {
                    ProgressView("Transcribing...")
                        .controlSize(.small)
                } else if let correction = viewModel.lastCorrection {
                    Text("✅ Grammar fixed")
                        .font(.system(size: 13))
                    Text("→ \(correction.correctedText)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 8) {
                        Text("Press Cmd + Shift + B to correct text")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Button(action: {
                            viewModel.startDictation()
                        }) {
                            HStack {
                                Image(systemName: "mic.fill")
                                Text("Start Dictation")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .frame(width: 360, height: 280)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(16)
        )
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}

