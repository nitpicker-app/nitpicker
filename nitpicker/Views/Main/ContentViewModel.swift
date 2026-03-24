//
//  MainViewModel.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation
import Combine

struct CorrectionEntry: Identifiable, Codable {
    let id: UUID
    let original: String
    let corrected: String
    let date: Date

    init(original: String, corrected: String, date: Date) {
        self.id = UUID()
        self.original = original
        self.corrected = corrected
        self.date = date
    }
}

@MainActor
class ContentViewModel: ObservableObject {

    enum CorrectionStatus: Equatable {
        case idle
        case correcting
        case done(corrected: String)
        case failed
    }

    private static let historyKey = "correctionHistory"

    @Published var correctionStatus: CorrectionStatus = .idle
    @Published var history: [CorrectionEntry] = ContentViewModel.loadHistory()

    init() {
        $history
            .dropFirst()
            .sink { ContentViewModel.saveHistory($0) }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private static func loadHistory() -> [CorrectionEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let entries = try? JSONDecoder().decode([CorrectionEntry].self, from: data)
        else { return [] }
        return entries
    }

    private static func saveHistory(_ entries: [CorrectionEntry]) {
        let data = try? JSONEncoder().encode(entries)
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    var hasAPIKey: Bool {
        !(KeychainService.shared.getAPIKey() ?? "").isEmpty
    }

    var hasAccessibilityPermission: Bool {
        AccessibilityPermissionManager.shared.hasAccessibilityPermissions
    }

    func correctSelectedText() {
        let permissionManager = AccessibilityPermissionManager.shared
        guard permissionManager.hasAccessibilityPermissions else {
            permissionManager.checkAndRequestAccessibilityPermissions(showUI: true)
            return
        }

        guard let selectedText = ClipboardHelper.copySelectedText() else { return }

        correctionStatus = .correcting

        Task {
            await TextCorrectionServiceFactory.current.correctGrammar(text: selectedText) { [weak self] corrected in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let corrected else {
                        self.correctionStatus = .failed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                            if case .failed = self?.correctionStatus ?? .idle {
                                self?.correctionStatus = .idle
                            }
                        }
                        return
                    }
                    ClipboardHelper.replaceSelectedText(with: corrected)
                    self.correctionStatus = .done(corrected: corrected)
                    let entry = CorrectionEntry(original: selectedText, corrected: corrected, date: Date())
                    self.history.insert(entry, at: 0)
                    if self.history.count > 10 {
                        self.history = Array(self.history.prefix(10))
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        if case .done = self?.correctionStatus ?? .idle {
                            self?.correctionStatus = .idle
                        }
                    }
                }
            }
        }
    }
}
