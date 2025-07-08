//
//  ClipBoardHelper.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Cocoa
import ApplicationServices

class ClipboardHelper {
    static func copySelectedText() -> String? {
        print("ClipboardHelper: Attempt to copy the selected text.")
        
        // Check for accessibility permissions using the centralized manager
        if !AccessibilityPermissionManager.shared.hasAccessibilityPermissions {
            print("ClipboardHelper: ⚠️ Accessibility permissions not granted")
            AccessibilityPermissionManager.shared.checkAndRequestAccessibilityPermissions(showUI: true)
            return nil
        }
        
        // Save current clipboard content
        let pb = NSPasteboard.general
        // We'll just clear the clipboard without saving previous content
        // as copying NSPasteboardItem causes crashes
        
        // Clear and prepare for new copy
        pb.clearContents()
        print("ClipboardHelper: Clipboard cleared for copy operation.")

        // Simulate Cmd+C to copy selected text
        let src = CGEventSource(stateID: .combinedSessionState)
        if src == nil {
            print("ClipboardHelper: ⚠️ Failed to create event source")
            return nil
        }
        
        // Key down for Cmd+C
        let cmdCDown = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: true)
        cmdCDown?.flags = .maskCommand
        cmdCDown?.post(tap: .cghidEventTap)
        print("ClipboardHelper: Key down Cmd+C posted")
        
        // Small delay
        usleep(100_000) // 100ms
        
        // Key up for Cmd+C
        let cmdCUp = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: false)
        cmdCUp?.flags = .maskCommand
        cmdCUp?.post(tap: .cghidEventTap)
        print("ClipboardHelper: Key up Cmd+C posted")

        // Wait for clipboard to be updated
        usleep(500_000) // 500ms should be enough
        
        // Get the copied text
        let selectedText = pb.string(forType: .string)
        
        if let text = selectedText {
            print("ClipboardHelper: Successfully copied text: \(text.prefix(20))...")
        } else {
            print("ClipboardHelper: ⚠️ No text was copied to clipboard")
        }
        
        return selectedText
    }
    
    // Remove duplicate alert method - using centralized version in AccessibilityPermissionManager

    static func replaceSelectedText(with text: String) {
        print("ClipboardHelper: Attempting to replace selected text")
        
        // Check for accessibility permissions using the centralized manager
        if !AccessibilityPermissionManager.shared.hasAccessibilityPermissions {
            print("ClipboardHelper: ⚠️ Accessibility permissions not granted")
            AccessibilityPermissionManager.shared.checkAndRequestAccessibilityPermissions(showUI: true)
            return
        }
        
        // Clear clipboard and set the corrected text
        let pb = NSPasteboard.general
        pb.clearContents()
        let success = pb.setString(text, forType: .string)
        
        if success {
            print("ClipboardHelper: Text set to clipboard successfully")
        } else {
            print("ClipboardHelper: ⚠️ Failed to set text to clipboard")
            return
        }

        // Create event source
        let src = CGEventSource(stateID: .combinedSessionState)
        if src == nil {
            print("ClipboardHelper: ⚠️ Failed to create event source")
            return
        }
        
        // Small delay before pasting
        usleep(100_000) // 100ms
        
        // Key down for Cmd+V
        let cmdVDown = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
        cmdVDown?.flags = .maskCommand
        cmdVDown?.post(tap: .cghidEventTap)
        print("ClipboardHelper: Key down Cmd+V posted")
        
        // Small delay
        usleep(100_000) // 100ms
        
        // Key up for Cmd+V
        let cmdVUp = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        cmdVUp?.flags = .maskCommand
        cmdVUp?.post(tap: .cghidEventTap)
        print("ClipboardHelper: Key up Cmd+V posted")
        
        // Wait a bit to ensure the paste completes
        usleep(300_000) // 300ms
        
        print("ClipboardHelper: Text replacement complete")
    }
}
