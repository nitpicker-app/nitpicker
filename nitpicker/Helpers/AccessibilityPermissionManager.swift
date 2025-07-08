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
    
    private let userDefaults = UserDefaults.standard
    private let permissionGrantedKey = "accessibilityPermissionGranted"
    private let lastCheckTimeKey = "accessibilityLastCheckTime"
    private let checkIntervalInDays = 7.0 // Check once per week at most
    
    var isPermissionGranted: Bool {
        return userDefaults.bool(forKey: permissionGrantedKey)
    }
    
    var shouldCheckPermission: Bool {
        // If permission was never granted, always check
        if !isPermissionGranted {
            return true
        }
        
        // If we already have permission, only check occasionally
        let lastCheckTime = userDefaults.double(forKey: lastCheckTimeKey)
        let currentTime = Date().timeIntervalSince1970
        let daysSinceLastCheck = (currentTime - lastCheckTime) / (60 * 60 * 24)
        
        return daysSinceLastCheck >= checkIntervalInDays
    }
    
    private func savePermissionStatus(_ granted: Bool) {
        userDefaults.set(granted, forKey: permissionGrantedKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastCheckTimeKey)
    }
    
    func checkAndRequestAccessibilityPermissions() {
        // Check if permission is actually granted at the system level without prompting
        let accessibilityEnabled = AXIsProcessTrusted()
        
        if accessibilityEnabled {
            // If we have permission now, save this status and return
            savePermissionStatus(true)
            print("✅ Accessibility permissions already granted")
            return
        }
        
        // No permission, show the prompt with options
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
        let accessibilityEnabledAfterPrompt = AXIsProcessTrustedWithOptions(options)
        
        if accessibilityEnabledAfterPrompt {
            // Permission was just granted after the prompt
            savePermissionStatus(true)
            print("✅ Accessibility permissions granted")
        } else {
            // User didn't grant permission or closed the system dialog
            savePermissionStatus(false)
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
        }
    }
    
    func resetPermissionStatus() {
        savePermissionStatus(false)
    }
}
