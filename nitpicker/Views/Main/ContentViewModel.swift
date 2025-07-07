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
        print("MainViewModel: Attempting to correct selected text")
        
        guard let selectedText = ClipboardHelper.copySelectedText() else {
            print("MainViewModel: No text selected or could not access clipboard")
            return
        }

        print("MainViewModel: Selected text: \(String(selectedText.prefix(50)))...")
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
