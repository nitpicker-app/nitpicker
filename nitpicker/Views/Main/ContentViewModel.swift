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
            // Capture screenshot of the active screen for context
            print("ContentViewModel: Capturing screenshot for visual context...")
            let screenshotData = await ScreenshotCaptureHelper.captureActiveScreen()
            
            if let screenshotData = screenshotData {
                print("ContentViewModel: Screenshot captured successfully (\(screenshotData.count) bytes)")
            } else {
                print("ContentViewModel: Screenshot capture failed, proceeding without visual context")
            }
            
            await TextCorrectionServiceFactory.current.correctGrammar(
                text: selectedText,
                screenshotData: screenshotData
            ) { [weak self] corrected in
                print("ContentViewModel: Received corrected text from service.")
                print("ContentViewModel: Corrected text: \(String(corrected.prefix(50)))...")
                DispatchQueue.main.async {
                    self?.lastCorrection = ClippedText(
                        originalText: selectedText,
                        correctedText: corrected,
                        screenshotData: screenshotData
                    )
                    print("ContentViewModel: Replacing selected text with corrected version")
                    ClipboardHelper.replaceSelectedText(with: corrected)
                    self?.isLoading = false
                }
            }
        }
    }
}
