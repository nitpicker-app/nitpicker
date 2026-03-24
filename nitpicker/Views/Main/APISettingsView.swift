//
//  APIKeyView.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import SwiftUI
import ServiceManagement

struct APISettingsView: View {
    @State private var apiKey: String = KeychainService.shared.getAPIKey() ?? ""
    @State private var showSaved = false
    @State private var errorMessage: String?
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5.4-mini"

    private let models: [(id: String, label: String)] = [
        ("gpt-5.4",      "GPT-5.4 — Flagship, best intelligence at scale"),
        ("gpt-5.4-mini", "GPT-5.4 Mini — Strong mini for coding & agents"),
        ("gpt-5.4-nano", "GPT-5.4 Nano — Cheapest & fastest GPT-5.4"),
        ("gpt-5-mini",   "GPT-5 Mini — Near-frontier, cost-sensitive"),
        ("gpt-5-nano",   "GPT-5 Nano — Fastest, most affordable GPT-5"),
        ("gpt-4.1",      "GPT-4.1 — Smartest non-reasoning model"),
        ("gpt-4.1-mini", "GPT-4.1 Mini — Smaller, faster GPT-4.1"),
        ("gpt-4.1-nano", "GPT-4.1 Nano — Fastest, cheapest GPT-4.1"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            updateLaunchAtLogin(newValue)
                        }
                } header: {
                    Text("General")
                }

                Section {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(models, id: \.id) { model in
                            Text(model.label).tag(model.id)
                        }
                    }
                    .onChange(of: selectedModel) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "selectedModel")
                    }
                } header: {
                    Text("AI Model")
                }

                Section {
                    SecureField("sk-...", text: $apiKey)
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Stored securely in your Keychain.")
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Group {
                    if showSaved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    } else if let msg = errorMessage {
                        Text(msg)
                            .foregroundStyle(.red)
                    }
                }
                .font(.callout)
                .transition(.opacity)

                Spacer()

                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .animation(.default, value: showSaved)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func save() {
        do {
            try KeychainService.shared.saveAPIKey(apiKey)
            withAnimation { showSaved = true }
            errorMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showSaved = false }
            }
        } catch {
            errorMessage = error.localizedDescription
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                errorMessage = nil
            }
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert the toggle if the system call failed
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

#Preview {
    APISettingsView()
        .frame(width: 360)
}

#Preview {
    APISettingsView()
}
