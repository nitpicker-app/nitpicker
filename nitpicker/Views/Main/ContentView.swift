//
//  ContentView.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject private var modeManager = ModeManager.shared
    var onOpenSettings: () -> Void = {}
    var onOpenHelp: () -> Void = {}
    @State private var copiedID: UUID?
    @State private var hoveredID: UUID?
    @State private var expandedID: UUID?

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

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.history.isEmpty {
            emptyState
        } else {
            historyList
        }
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
            Button {
                openSettings()
            } label: {
                Image(systemName: "gear")
                    .imageScale(.medium)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            if !viewModel.hasAPIKey {
                warningLabel("API key not configured", systemImage: "key.fill")
            } else if !viewModel.hasAccessibilityPermission {
                warningLabel("Accessibility permission required", systemImage: "lock.shield")
            } else {
                Text("⌘⇧B")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("Select text and press ⌘⇧B to correct it")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 24)
    }

    private func warningLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.callout)
            .foregroundStyle(.orange)
    }

    // MARK: - History

    private var historyList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Corrections")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                if case .correcting = viewModel.correctionStatus {
                    ProgressView().controlSize(.mini)
                } else {
                    Button("Clear") {
                        viewModel.history.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 2)

            ForEach(viewModel.history) { entry in
                historyRow(entry)
            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: viewModel.history.map(\.id))
    }

    private func historyRow(_ entry: CorrectionEntry) -> some View {
        let isCopied = copiedID == entry.id
        let isHovered = hoveredID == entry.id
        let isExpanded = expandedID == entry.id
        let diff = diffAttributedString(original: entry.original, corrected: entry.corrected)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(diff)
                    .font(.caption)
                    .lineLimit(isExpanded ? nil : 1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCopied {
                    Image(systemName: "checkmark")
                        .imageScale(.small)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                } else if isExpanded {
                    Button {
                        copyToClipboard(entry.corrected, id: entry.id)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                } else {
                    Text(entry.date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hoveredID = $0 ? entry.id : nil }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedID = isExpanded ? nil : entry.id
            }
        }
        .contextMenu {
            Button("Copy Corrected") {
                copyToClipboard(entry.corrected, id: entry.id)
            }
            Button("Copy Original") {
                copyToClipboard(entry.original, id: nil)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isCopied)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func copyToClipboard(_ text: String, id: UUID?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        if let id {
            withAnimation(.easeInOut(duration: 0.15)) { copiedID = id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if copiedID == id { copiedID = nil }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("About") {
                NSApp.orderFrontStandardAboutPanel(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.callout)

            Button("Help") {
                onOpenHelp()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.callout)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func openSettings() {
        onOpenSettings()
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
