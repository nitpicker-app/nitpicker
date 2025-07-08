//
//  AccessibilityPermissionManager.swift
//  nitpicker
//
//  Created on 07/07/25.
//

import Foundation
import Cocoa

final class AccessibilityPermissionManager {
    static let shared = AccessibilityPermissionManager()

    /// Checks whether the app currently has accessibility permission.
    var hasAccessibilityPermissions: Bool {
        AXIsProcessTrusted()
    }

    /// Checks for accessibility permissions and optionally prompts the user.
    /// - Parameter showUI: Whether to show UI prompts if permission is not granted.
    /// - Returns: `true` if permission is already granted, `false` otherwise.
    @discardableResult
    func checkAndRequestAccessibilityPermissions(showUI: Bool = true) -> Bool {
        if hasAccessibilityPermissions {
            return true
        }

        if showUI {
            promptUserToEnableAccessibility()
        }

        return false
    }

    /// Prompts the user with an alert explaining the need for accessibility permissions
    /// and offers to open the System Settings. If permission is still not granted afterward,
    /// a restart is suggested.
    private func promptUserToEnableAccessibility() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = """
            Nitpicker needs accessibility permissions to capture and replace text.
            Please enable this in System Settings → Privacy & Security → Accessibility.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                self.openAccessibilitySettings()

                // Give the user a moment to act, then recheck and possibly offer a restart
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if !self.hasAccessibilityPermissions {
                        self.showRestartAlert()
                    }
                }
            }
        }
    }

    /// Opens the System Settings directly to the Accessibility section.
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Prompts the user to restart the app in order for permission changes to take effect.
    private func showRestartAlert() {
        let alert = NSAlert()
        alert.messageText = "Restart Required"
        alert.informativeText = "Please restart Nitpicker to apply the newly granted Accessibility permissions."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            relaunchApp()
        }
    }

    /// Relaunches the current app instance.
    func relaunchApp() {
        guard let bundlePath = Bundle.main.bundlePath as String? else { return }

        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", bundlePath]
        task.launch()

        NSApp.terminate(nil)
    }
}
