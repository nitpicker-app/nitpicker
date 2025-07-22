//
//  MainViewModel.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var lastCorrection: ClippedText?

    func correctSelectedText() {
        // First verify accessibility permissions are granted
        let permissionManager = AccessibilityPermissionManager.shared
        if !permissionManager.hasAccessibilityPermissions {
            print("ContentViewModel: ⚠️ Cannot correct text - accessibility permissions not granted")
            permissionManager.checkAndRequestAccessibilityPermissions(showUI: true)
            return
        }
        
        guard let selectedText = ClipboardHelper.copySelectedText() else {
            return
        }
        
        isLoading = true

        Task {
            await TextCorrectionServiceFactory.current.correctGrammar(text: selectedText) { [weak self] corrected in
                print("ContentViewModel: Received corrected text from service.")
                print("ContentViewModel: Corrected text: \(String(corrected.prefix(50)))...")
                DispatchQueue.main.async {
                    self?.lastCorrection = ClippedText(originalText: selectedText, correctedText: corrected)
                    print("ContentViewModel: Replacing selected text with corrected version")
                    ClipboardHelper.replaceSelectedText(with: corrected)
                    self?.isLoading = false
                }
            }
        }
    }
}
