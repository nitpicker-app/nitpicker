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
    @State private var showSaved = false
    @State private var errorMessage: String?
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5.4-mini"
    @State private var editingMode: CorrectionMode?
    @State private var isAddingMode = false
    @State private var draftMode = CorrectionMode(id: "", name: "", systemPrompt: "")

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

                Section {
                    if modeManager.customModes.isEmpty {
                        Text("No custom modes yet.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
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
        .frame(width: 360)
}

#Preview {
    APISettingsView()
}
