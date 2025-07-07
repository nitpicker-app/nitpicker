//
//  nitpickerApp.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import SwiftUI
import SwiftData

@main
struct nitpickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
