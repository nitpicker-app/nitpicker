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
        
        guard let selectedText = ClipboardHelper.copySelectedText() else {
            return
        }
        
        isLoading = true

        OpenAIService.shared.correctGrammar(text: selectedText) { [weak self] corrected in
            print("MainViewModel: Received corrected text from OpenAI.")
            print("MainViewModel: Corrected text: \(String(corrected.prefix(50)))...")
            DispatchQueue.main.async {
                self?.lastCorrection = ClippedText(originalText: selectedText, correctedText: corrected)
                print("MainViewModel: Replacing selected text with corrected version")
                ClipboardHelper.replaceSelectedText(with: corrected)
                self?.isLoading = false
            }
        }
    }
}
