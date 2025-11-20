//
//  TextCorrectionService.swift
//  nitpicker
//
//  Created by Vishnu R on 22/07/25.
//

import Foundation

/// Protocol defining the interface for text correction services
protocol TextCorrectionService {
    /// Corrects grammar, spelling, and punctuation in the given text
    /// - Parameters:
    ///   - text: The text to be corrected
    ///   - screenshotData: Optional screenshot data providing visual context for the correction
    ///   - completion: Completion handler called with the corrected text
    func correctGrammar(text: String, screenshotData: Data?, completion: @escaping (String) -> Void) async
}
