//
//  APIKeyView.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import SwiftUI

struct APISettingsView: View {
    @State private var apiKey: String =
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var isSaved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("OpenAI API Key")
                .font(.system(size: 16, weight: .semibold))

            Divider()
                .padding(.bottom, 4)

            Text("Enter your API key to use Nitpicker")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            SecureField("Enter your API key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)

            Button("Save") {
                UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
                isSaved = true

                // Hide the saved message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSaved = false
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .frame(maxWidth: 100)

            if isSaved {
                Text("API key saved!")
                    .foregroundColor(.green)
                    .font(.system(size: 13))
                    .padding(.top, 4)
            }

            Divider()
                .padding(.vertical, 8)

            Text("Your API key is stored locally on this device only.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

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
    APISettingsView()
}
