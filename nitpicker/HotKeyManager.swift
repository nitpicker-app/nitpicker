//
//  HotKeyManager.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import HotKey

class HotKeyManager {
    static let shared = HotKeyManager()
    private var correctionHotKey: HotKey?

    func registerCorrectionHotKey(action: @escaping () -> Void) {
        correctionHotKey = HotKey(key: .b, modifiers: [.command, .shift])
        correctionHotKey?.keyDownHandler = action
    }
}
