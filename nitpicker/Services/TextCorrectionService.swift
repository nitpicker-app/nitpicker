//
//  TextCorrectionService.swift
//  nitpicker
//
//  Created by Vishnu R on 22/07/25.
//

import Foundation

/// Protocol defining the interface for text correction services
protocol TextCorrectionService {
    /// Corrects grammar, spelling, and punctuation in the given text.
    /// - Parameters:
    ///   - text: The text to be corrected
    ///   - completion: Called with the corrected string on success, or `nil` on failure
    func correctGrammar(text: String, completion: @escaping (String?) -> Void) async
}
