//
//  HelpView.swift
//  nitpicker
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                helpSection("Getting Started") {
                    helpRow(icon: "1.circle.fill", color: .blue,
                            title: "Grant Accessibility permission",
                            detail: "Required once. System Settings → Privacy & Security → Accessibility.")
                    helpRow(icon: "2.circle.fill", color: .blue,
                            title: "Add your OpenAI API key",
                            detail: "Click ⚙ in the popover to open Settings. The key is stored securely in your Keychain.")
                    helpRow(icon: "3.circle.fill", color: .blue,
                            title: "Select text and press ⌘ ⇧ B",
                            detail: "Works in any app — browser, email, editor, chat.")
                }

                helpSection("Correction Modes") {
                    helpRow(icon: "text.badge.checkmark", color: .green,
                            title: "Grammar",
                            detail: "Fixes spelling, grammar, and punctuation without changing your words.")
                    helpRow(icon: "briefcase", color: .indigo,
                            title: "Formal",
                            detail: "Rewrites text in a professional, formal tone.")
                    helpRow(icon: "scissors", color: .orange,
                            title: "Concise",
                            detail: "Removes filler and redundancy while preserving meaning.")
                    helpRow(icon: "globe", color: .teal,
                            title: "Translate",
                            detail: "Translates selected text to your chosen language. Pick the target language from the popover.")
                }

                helpSection("Custom Modes") {
                    helpRow(icon: "plus.circle", color: .purple,
                            title: "Create your own mode",
                            detail: "Settings → Custom Modes → Add Mode. Write a system prompt that describes how the AI should transform text.")
                }

                helpSection("Correction History") {
                    helpRow(icon: "clock", color: .secondary,
                            title: "Recent corrections",
                            detail: "The popover shows your last 10 corrections with word-level diff — deletions in red, insertions in green.")
                    helpRow(icon: "doc.on.doc", color: .secondary,
                            title: "Copy corrected text",
                            detail: "Click any row to copy the corrected text. Hover to reveal the copy icon. Right-click for additional options including copying the original.")
                    helpRow(icon: "info.circle", color: .secondary,
                            title: "See the original",
                            detail: "Hover over a correction and hold — a tooltip shows the original text before changes.")
                }

                helpSection("Troubleshooting") {
                    helpRow(icon: "lock.shield", color: .orange,
                            title: "Accessibility permission not granted",
                            detail: "Open System Settings → Privacy & Security → Accessibility and enable Nitpicker.")
                    helpRow(icon: "key", color: .orange,
                            title: "API key missing or invalid",
                            detail: "Open Settings (⚙) and paste a valid OpenAI API key starting with sk-.")
                    helpRow(icon: "exclamationmark.triangle", color: .orange,
                            title: "Correction failed",
                            detail: "Check your internet connection and that your API key has available credits.")
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 500)
    }

    private func helpSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func helpRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    HelpView()
}
