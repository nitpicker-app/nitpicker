//
//  HelpView.swift
//  nitpicker
//
//  Created by Vishnu R on 08/07/25.
//

import SwiftUI

public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            Text("Nitpicker Help")
                .font(.system(size: 16, weight: .semibold))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("How to Use")
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Select text anywhere in macOS")
                                .font(.system(size: 13))
                            Text("• Press Cmd+Shift+B to correct grammar")
                                .font(.system(size: 13))
                            Text(
                                "• Nitpicker will replace the text automatically"
                            )
                            .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Group {
                        Text("Voice Dictation")
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Press Cmd+Shift+D to start dictation")
                                .font(.system(size: 13))
                            Text("• Speak your text into the microphone")
                                .font(.system(size: 13))
                            Text("• Press Cmd+Shift+D again to stop and transcribe")
                                .font(.system(size: 13))
                            Text("• The transcribed text will be corrected and pasted")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                    }

                    Group {
                        Text("API Settings")
                            .font(.system(size: 13, weight: .semibold))

                        Text(
                            "Nitpicker uses OpenAI's API to correct grammar. You need to provide your own API key in the settings."
                        )
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    }

                    Group {
                        Text("Accessibility")
                            .font(.system(size: 13, weight: .semibold))

                        Text(
                            "The app requires accessibility permissions to read and replace text, and microphone access for dictation. You can grant these in System Settings → Privacy & Security."
                        )
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .frame(width: 400, height: 460)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(16)
        )
    }
}

#Preview {
    HelpView()
}
