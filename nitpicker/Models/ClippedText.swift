//
//  ClippedText.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation

struct ClippedText {
    let originalText: String
    let correctedText: String
    let screenshotData: Data?
    
    init(originalText: String, correctedText: String, screenshotData: Data? = nil) {
        self.originalText = originalText
        self.correctedText = correctedText
        self.screenshotData = screenshotData
    }
}
