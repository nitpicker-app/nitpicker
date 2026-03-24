//
//  APIKeyView.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import SwiftUI
import ServiceManagement

struct APISettingsView: View {
    @ObservedObject private var modeManager = ModeManager.shared
    @State private var apiKey: String = KeychainService.shared.getAPIKey() ?? ""
    @State private var apiKeySaveState: SaveState = .idle
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5.4-mini"
    @State private var editingMode: CorrectionMode?
    @State private var isAddingMode = false
    @State private var draftMode = CorrectionMode(id: "", name: "", systemPrompt: "")
    @FocusState private var apiKeyFocused: Bool

    private enum SaveState: Equatable {
        case idle, saved, error(String)
    }

    private let models: [(id: String, label: String)] = [
        ("gpt-5.4",      "GPT-5.4"),
        ("gpt-5.4-mini", "GPT-5.4 Mini"),
        ("gpt-5.4-nano", "GPT-5.4 Nano"),
        ("gpt-5-mini",   "GPT-5 Mini"),
        ("gpt-5-nano",   "GPT-5 Nano"),
        ("gpt-4.1",      "GPT-4.1"),
        ("gpt-4.1-mini", "GPT-4.1 Mini"),
        ("gpt-4.1-nano", "GPT-4.1 Nano"),
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
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
                .onChange(of: selectedModel) { _, newValue in
                    UserDefaults.standard.set(newValue, forKey: "selectedModel")
                }
            } header: {
                Text("AI Model")
            }

            Section {
                SecureField("sk-...", text: $apiKey)
                    .focused($apiKeyFocused)
                    .onSubmit { saveAPIKey() }
                    .onChange(of: apiKeyFocused) { _, focused in
                        if !focused { saveAPIKey() }
                    }
            } header: {
                Text("OpenAI API Key")
            } footer: {
                Group {
                    switch apiKeySaveState {
                    case .idle:
                        Text("Stored securely in your Keychain.")
                    case .saved:
                        Label("Saved to Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                    case .error(let msg):
                        Text(msg).foregroundStyle(.red)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: apiKeySaveState)
            }

            Section {
                if modeManager.customModes.isEmpty {
                    Text("No custom modes yet.")
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(modeManager.customModes) { mode in
                        HStack {
                            Text(mode.name)
                            Spacer()
                            Button {
                                draftMode = mode
                                editingMode = mode
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Edit")

                            Button {
                                modeManager.deleteMode(id: mode.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                            .help("Delete")
                        }
                    }
                }

                Button {
                    draftMode = CorrectionMode(id: UUID().uuidString, name: "", systemPrompt: "")
                    isAddingMode = true
                } label: {
                    Label("Add Mode", systemImage: "plus")
                }
            } header: {
                Text("Custom Modes")
            } footer: {
                Text("Custom modes appear in the mode picker and use your system prompt.")
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $isAddingMode) {
            ModeEditView(mode: $draftMode, title: "New Mode") {
                modeManager.addMode(draftMode)
                isAddingMode = false
            } onCancel: {
                isAddingMode = false
            }
        }
        .sheet(item: $editingMode) { _ in
            ModeEditView(mode: $draftMode, title: "Edit Mode") {
                modeManager.updateMode(draftMode)
                editingMode = nil
            } onCancel: {
                editingMode = nil
            }
        }
    }

    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        do {
            try KeychainService.shared.saveAPIKey(apiKey)
            withAnimation { apiKeySaveState = .saved }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { apiKeySaveState = .idle }
            }
        } catch {
            apiKeySaveState = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                apiKeySaveState = .idle
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
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - Mode Edit Sheet

struct ModeEditView: View {
    @Binding var mode: CorrectionMode
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Name") {
                    TextField("e.g. Friendly, Technical, Summary…", text: $mode.name)
                }
                Section {
                    TextEditor(text: $mode.systemPrompt)
                        .font(.body)
                        .frame(minHeight: 120)
                } header: {
                    Text("System Prompt")
                } footer: {
                    Text("Describe how the AI should transform the selected text.")
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(title == "New Mode" ? "Add" : "Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(mode.name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              mode.systemPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 380, height: 320)
    }
}

#Preview {
    APISettingsView()
        .frame(width: 380)
}
