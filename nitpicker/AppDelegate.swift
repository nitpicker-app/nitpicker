//
//  AppDelegate.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let viewModel = ContentViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        let permissionManager = AccessibilityPermissionManager.shared
        if !permissionManager.hasAccessibilityPermissions {
            permissionManager.checkAndRequestAccessibilityPermissions(showUI: true)
        }

        statusBarController = StatusBarController(viewModel: viewModel)
        setupApplicationMenu()

        HotKeyManager.shared.registerCorrectionHotKey { [weak self] in
            self?.viewModel.correctSelectedText()
        }

        if !viewModel.hasAPIKey {
            statusBarController?.openSettings()
        }
    }

    func setupApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        let appName = NSRunningApplication.current.localizedName ?? "Nitpicker"

        appMenu.addItem(
            NSMenuItem(
                title: "About \(appName)",
                action: #selector(showAbout),
                keyEquivalent: ""
            )
        )
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(
            NSMenuItem(
                title: "Settings…",
                action: #selector(showAPISettings),
                keyEquivalent: ","
            )
        )
        appMenu.addItem(NSMenuItem.separator())

        // Standard application menu items
        appMenu.addItem(
            NSMenuItem(
                title: "Hide \(appName)",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h"
            )
        )
        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.option, .command]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(
            NSMenuItem(
                title: "Show All",
                action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""
            )
        )
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(
            NSMenuItem(
                title: "Quit \(appName)",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        // Help menu
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)

        let helpMenu = NSMenu(title: "Help")
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(
            NSMenuItem(
                title: "\(appName) Help",
                action: #selector(showHelp),
                keyEquivalent: "?"
            )
        )

        NSApp.mainMenu = mainMenu
    }

    @objc func showAPISettings() {
        statusBarController?.openSettings()
    }

    @objc func showAbout() {
        statusBarController?.showAbout()
    }

    @objc func showHelp() {
        statusBarController?.openHelp()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        print("Application became active")
    }

}
