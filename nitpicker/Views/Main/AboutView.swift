//
//  AboutView.swift
//  nitpicker
//
//  Created by Vishnu R on 08/07/25.
//

import SwiftUI

struct AboutView: View {
    
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Text("About Nitpicker")
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
                .padding(.bottom, 8)

            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .padding(.bottom, 8)
            }
            
            Text("Nitpicker")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Version 1.0")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text("Grammar correction for macOS")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Divider()
                .padding(.vertical, 4)
            
            Text("© 2025 Vishnu R. All rights reserved.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button("Credits") {
                    // Could be implemented later
                }
                .buttonStyle(LinkButtonStyle())
                
                Button("Website") {
                    if let url = URL(string: "https://github.com/vishnu/nitpicker") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(LinkButtonStyle())
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
        .frame(width: 340, height: 320)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(20)
        )
    }
}

#Preview {
    AboutView()
}
