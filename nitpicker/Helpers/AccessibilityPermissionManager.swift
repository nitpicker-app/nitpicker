//
//  AccessibilityPermissionManager.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import Foundation
import Cocoa

class AccessibilityPermissionManager {
    static let shared = AccessibilityPermissionManager()
    
    func checkAndRequestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessibilityEnabled {
            print("⚠️ Accessibility permissions are required for Nitpicker to function properly.")
            print("⚠️ Please grant accessibility permissions in System Preferences -> Security & Privacy -> Privacy -> Accessibility")
            
            // Create an alert to inform the user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "Nitpicker needs accessibility permissions to capture and replace text. Please grant accessibility permissions in System Preferences -> Security & Privacy -> Privacy -> Accessibility"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Later")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Open the Security & Privacy preferences
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
                }
            }
        } else {
            print("✅ Accessibility permissions granted")
        }
    }
}
