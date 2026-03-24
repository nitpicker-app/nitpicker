//
//  ContentView.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI

private class HistoryState: ObservableObject {
    @Published var copiedID: UUID?
    @Published var hoveredID: UUID?
}

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject private var modeManager = ModeManager.shared
    var onOpenSettings: () -> Void = {}
    var onOpenHelp: () -> Void = {}
    @StateObject private var historyState = HistoryState()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if modeManager.activeModeID == "translate" {
                translateLanguagePicker
                Divider()
            }
            mainContent
            Divider()
            footer
        }
        .frame(width: 280)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text("Nitpicker")
                .font(.headline)
            Spacer()
            if case .correcting = viewModel.correctionStatus {
                ProgressView().controlSize(.small)
            }
            modePicker
            Button { onOpenSettings() } label: {
                Image(systemName: "gear").imageScale(.medium)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var modePicker: some View {
        Menu {
            ForEach(modeManager.allModes) { mode in
                Button {
                    modeManager.activeModeID = mode.id
                } label: {
                    if modeManager.activeModeID == mode.id {
                        Label(mode.name, systemImage: "checkmark")
                    } else {
                        Text(mode.name)
                    }
                }
            }
        } label: {
            Text(modeManager.activeMode.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Translate

    private static let translateLanguages = [
        "English", "Spanish", "French", "German", "Italian", "Portuguese",
        "Dutch", "Russian", "Chinese", "Japanese", "Korean", "Arabic", "Hindi"
    ]

    private var translateLanguagePicker: some View {
        HStack {
            Text("Translate to")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: $modeManager.translateTargetLanguage) {
                ForEach(Self.translateLanguages, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.history.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            if !viewModel.hasAPIKey {
                Label("API key not configured", systemImage: "key.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else if !viewModel.hasAccessibilityPermission {
                Label("Accessibility permission required", systemImage: "lock.shield")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else {
                Text("⌘ ⇧ B")
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                Text("Select text anywhere and press the shortcut to correct it.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }

    // MARK: - History list

    private var historyList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.history) { entry in
                    historyRow(entry)
                    if entry.id != viewModel.history.last?.id {
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
        }
        .frame(maxHeight: 320)
    }

    private func historyRow(_ entry: CorrectionEntry) -> some View {
        let isCopied = historyState.copiedID == entry.id
        let isHovered = historyState.hoveredID == entry.id

        return HStack(alignment: .top, spacing: 10) {
            Text(diffAttributedString(original: entry.original, corrected: entry.corrected))
                .font(.caption)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .imageScale(.small)
                .foregroundStyle(isCopied ? .green : .secondary)
                .frame(width: 16, height: 16)
                .opacity(isHovered || isCopied ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: isHovered)
                .animation(.easeInOut(duration: 0.15), value: isCopied)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { historyState.hoveredID = $0 ? entry.id : nil }
        .onTapGesture { copyToClipboard(entry.corrected, id: entry.id) }
        .help("Original: \(entry.original)")
        .contextMenu {
            Button("Copy Corrected") { copyToClipboard(entry.corrected, id: entry.id) }
            Button("Copy Original") { copyToClipboard(entry.original, id: nil) }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if !viewModel.history.isEmpty {
                Button("Clear") {
                    viewModel.history.removeAll()
                    historyState.hoveredID = nil
                    historyState.copiedID = nil
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
            Spacer()
            Button("Help") { onOpenHelp() }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func copyToClipboard(_ text: String, id: UUID?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        guard let id else { return }
        withAnimation(.easeInOut(duration: 0.15)) { historyState.copiedID = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.15)) {
                if self.historyState.copiedID == id { self.historyState.copiedID = nil }
            }
        }
    }
}

// MARK: - Diff Helpers

private enum DiffSegment {
    case equal(String)
    case deleted(String)
    case inserted(String)
}

private func wordDiff(original: String, corrected: String) -> [DiffSegment] {
    let a = original.components(separatedBy: " ").filter { !$0.isEmpty }
    let b = corrected.components(separatedBy: " ").filter { !$0.isEmpty }
    if a.isEmpty { return b.map { .inserted($0) } }
    if b.isEmpty { return a.map { .deleted($0) } }

    let m = a.count, n = b.count
    var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
    for i in 1...m {
        for j in 1...n {
            dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
        }
    }

    var result: [DiffSegment] = []
    var i = m, j = n
    while i > 0 || j > 0 {
        if i > 0 && j > 0 && a[i-1] == b[j-1] {
            result.append(.equal(a[i-1])); i -= 1; j -= 1
        } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
            result.append(.inserted(b[j-1])); j -= 1
        } else {
            result.append(.deleted(a[i-1])); i -= 1
        }
    }
    return result.reversed()
}

private func diffAttributedString(original: String, corrected: String) -> AttributedString {
    let segments = wordDiff(original: original, corrected: corrected)
    var result = AttributedString()
    for (i, segment) in segments.enumerated() {
        let space = i < segments.count - 1 ? " " : ""
        switch segment {
        case .equal(let w):
            result += AttributedString(w + space)
        case .deleted(let w):
            var attr = AttributedString(w + space)
            attr.foregroundColor = Color.red
            attr.strikethroughStyle = NSUnderlineStyle.single
            result += attr
        case .inserted(let w):
            var attr = AttributedString(w + space)
            attr.foregroundColor = Color.green
            result += attr
        }
    }
    return result
}

#Preview {
    ContentView(viewModel: ContentViewModel())
}
