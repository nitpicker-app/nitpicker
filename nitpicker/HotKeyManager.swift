//
//  HotKeyManager.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import HotKey

class HotKeyManager {
    static let shared = HotKeyManager()
    private var hotKey: HotKey?

    func registerHotKey(action: @escaping () -> Void) {
        hotKey = HotKey(key: .b, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = action
    }
}
