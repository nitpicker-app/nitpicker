//
//  ModeManager.swift
//  nitpicker
//

import Foundation

struct CorrectionMode: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var systemPrompt: String
    var isBuiltIn: Bool = false
}

extension CorrectionMode {
    static let grammar = CorrectionMode(
        id: "grammar",
        name: "Grammar",
        systemPrompt: """
            You are a grammar correction assistant. Fix grammar, spelling, and punctuation errors in the provided text.

            Rules:
            - Fix grammar, spelling, and punctuation only
            - Do not rephrase, restructure, or rewrite sentences
            - Do not change word choice unless it is clearly a spelling error
            - Preserve the author's tone, style, and sentence structure exactly
            - Return ONLY the corrected text — no explanations, comments, or markup
            """,
        isBuiltIn: true
    )

    static let formal = CorrectionMode(
        id: "formal",
        name: "Formal",
        systemPrompt: """
            You are a writing assistant that rewrites text in a formal, professional tone.

            Rules:
            - Rewrite the text to sound formal and professional
            - Fix any grammar, spelling, and punctuation errors
            - Replace casual or colloquial language with formal alternatives
            - Preserve the core meaning and all key information
            - Return ONLY the rewritten text — no explanations or markup
            """,
        isBuiltIn: true
    )

    static let concise = CorrectionMode(
        id: "concise",
        name: "Concise",
        systemPrompt: """
            You are a writing assistant that makes text more concise.

            Rules:
            - Remove unnecessary words, filler, and redundancy
            - Preserve the complete meaning and all key information
            - Do not introduce new information
            - Fix any grammar errors while editing
            - Return ONLY the rewritten text — no explanations or markup
            """,
        isBuiltIn: true
    )

    // Prompt is generated dynamically by ModeManager based on translateTargetLanguage
    static let translate = CorrectionMode(
        id: "translate",
        name: "Translate",
        systemPrompt: "",
        isBuiltIn: true
    )

    static let builtIns: [CorrectionMode] = [.grammar, .formal, .concise, .translate]
}

class ModeManager: ObservableObject {
    static let shared = ModeManager()

    @Published var customModes: [CorrectionMode] = [] {
        didSet { saveCustomModes() }
    }

    @Published var activeModeID: String = "grammar" {
        didSet { UserDefaults.standard.set(activeModeID, forKey: "activeModeID") }
    }

    @Published var translateTargetLanguage: String = "English" {
        didSet { UserDefaults.standard.set(translateTargetLanguage, forKey: "translateTargetLanguage") }
    }

    var allModes: [CorrectionMode] { CorrectionMode.builtIns + customModes }

    var activeMode: CorrectionMode {
        allModes.first { $0.id == activeModeID } ?? .grammar
    }

    var effectiveSystemPrompt: String {
        guard activeModeID != "translate" else {
            return """
                Translate the provided text to \(translateTargetLanguage).

                Rules:
                - Return ONLY the translated text
                - Preserve formatting (line breaks, paragraph structure) where appropriate
                - Do not add explanations, notes, or markup
                """
        }
        return activeMode.systemPrompt
    }

    private init() {
        activeModeID = UserDefaults.standard.string(forKey: "activeModeID") ?? "grammar"
        translateTargetLanguage = UserDefaults.standard.string(forKey: "translateTargetLanguage") ?? "English"
        loadCustomModes()
    }

    func addMode(_ mode: CorrectionMode) {
        customModes.append(mode)
    }

    func updateMode(_ mode: CorrectionMode) {
        guard let idx = customModes.firstIndex(where: { $0.id == mode.id }) else { return }
        customModes[idx] = mode
    }

    func deleteMode(id: String) {
        customModes.removeAll { $0.id == id }
        if activeModeID == id { activeModeID = "grammar" }
    }

    private func saveCustomModes() {
        guard let data = try? JSONEncoder().encode(customModes) else { return }
        UserDefaults.standard.set(data, forKey: "customModes")
    }

    private func loadCustomModes() {
        guard let data = UserDefaults.standard.data(forKey: "customModes"),
              let modes = try? JSONDecoder().decode([CorrectionMode].self, from: data)
        else { return }
        customModes = modes
    }
}
