//
//  MainViewModel.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation
import Combine

struct CorrectionEntry: Identifiable {
    let id = UUID()
    let original: String
    let corrected: String
    let date: Date
}

class ContentViewModel: ObservableObject {

    enum CorrectionStatus: Equatable {
        case idle
        case correcting
        case done(corrected: String)
        case failed
    }

    @Published var correctionStatus: CorrectionStatus = .idle
    @Published var history: [CorrectionEntry] = []

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
                    guard let corrected else {
                        self?.correctionStatus = .failed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            if case .failed = self?.correctionStatus ?? .idle {
                                self?.correctionStatus = .idle
                            }
                        }
                        return
                    }
                    ClipboardHelper.replaceSelectedText(with: corrected)
                    self?.correctionStatus = .done(corrected: corrected)
                    let entry = CorrectionEntry(original: selectedText, corrected: corrected, date: Date())
                    self?.history.insert(entry, at: 0)
                    if (self?.history.count ?? 0) > 10 {
                        self?.history = Array(self!.history.prefix(10))
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if case .done = self?.correctionStatus ?? .idle {
                            self?.correctionStatus = .idle
                        }
                    }
                }
            }
        }
    }
}
