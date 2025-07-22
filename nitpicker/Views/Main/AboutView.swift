//
//  AboutView.swift
//  nitpicker
//
//  Created by Vishnu R on 08/07/25.
//

import SwiftUI

struct AboutView: View {

    @Environment(\.dismiss) private var dismiss
    // Get the app version from the main bundle
    private var appVersion: String {
        let version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0"
        let build =
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .padding(.bottom, 8)
            }

            Text("Nitpicker")
                .font(.system(size: 16, weight: .semibold))

            Text(appVersion)
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

            Button("Website") {
                if let url = URL(
                    string: "https://github.com/nitpicker-app/nitpicker"
                ) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(LinkButtonStyle())
        }
        .padding()
        .frame(width: 360, height: 360)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(16)
        )
    }
}

#Preview {
    AboutView()
}
