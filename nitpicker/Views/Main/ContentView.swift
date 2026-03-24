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
    var onOpenSettings: () -> Void = {}
    @State private var copiedID: UUID?
    @State private var hoveredID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
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
        HStack {
            Text("Nitpicker")
                .font(.headline)
            Spacer()
            if case .correcting = viewModel.correctionStatus, viewModel.history.isEmpty {
                ProgressView().controlSize(.small)
            }
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

        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.corrected)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(entry.original)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isCopied {
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            } else {
                Text(entry.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hoveredID = $0 ? entry.id : nil }
        .onTapGesture {
            copyToClipboard(entry.corrected, id: entry.id)
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

#Preview {
    ContentView(viewModel: ContentViewModel())
}
