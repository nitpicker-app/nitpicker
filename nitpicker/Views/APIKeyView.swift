//
//  APIKeyView.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import SwiftUI

struct APIKeyView: View {
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var isSaved = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("OpenAI API Key")
                .font(.headline)
            
            SecureField("Enter your API key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Save") {
                UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
                isSaved = true
                
                // Hide the saved message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSaved = false
                }
            }
            .buttonStyle(.borderedProminent)
            
            if isSaved {
                Text("API key saved!")
                    .foregroundColor(.green)
            }
            
            Text("Your API key is stored locally on this device only.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    APIKeyView()
}
