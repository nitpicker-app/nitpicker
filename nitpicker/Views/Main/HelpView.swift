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
            ZStack {
                Text("Nitpicker Help")
                    .font(.system(size: 16, weight: .semibold))

                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("How to Use")
                            .font(.system(size: 13, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Select text anywhere in macOS")
                                .font(.system(size: 13))
                            Text("2. Press Cmd+Shift+B to correct grammar")
                                .font(.system(size: 13))
                            Text("3. Nitpicker will replace the text automatically")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Group {
                        Text("API Settings")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Text("Nitpicker uses OpenAI's API to correct grammar. You need to provide your own API key in the settings.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Group {
                        Text("Accessibility")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Text("The app requires accessibility permissions to read and replace text. You can grant these in System Settings → Privacy & Security → Accessibility.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .frame(width: 380, height: 350)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(20)
        )
    }
}


#Preview {
    HelpView()
}
