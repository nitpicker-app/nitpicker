//
//  AppDelegate.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let viewModel = ContentViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching")
        
        // Check accessibility permissions with improved logic
        let permissionManager = AccessibilityPermissionManager.shared
        
        // Always check the actual system permission status
        if !permissionManager.hasAccessibilityPermissions {
            print("⚠️ Accessibility permissions not granted - requesting now")
            permissionManager.checkAndRequestAccessibilityPermissions(showUI: true)
        }
        
        let contentView = ContentView(viewModel: viewModel)
        statusBarController = StatusBarController(contentView: contentView)
        
        // Set up the application menu
        setupApplicationMenu()
        
        // Register hotkey for grammar correction
        HotKeyManager.shared.registerHotKey { [weak self] in
            print("HotKey triggered: Cmd+Shift+G")
            self?.viewModel.correctSelectedText()
        }
    }
    
    func setupApplicationMenu() {
        let mainMenu = NSMenu()
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        let appName = NSRunningApplication.current.localizedName ?? "Nitpicker"
        
        appMenu.addItem(NSMenuItem(title: "About \(appName)", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        
        appMenu.addItem(NSMenuItem(title: "API Settings", action: #selector(showAPISettings), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        
        // Standard application menu items
        appMenu.addItem(NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.option, .command]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        
        appMenu.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // Help menu
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        
        let helpMenu = NSMenu(title: "Help")
        helpMenuItem.submenu = helpMenu
        
        helpMenu.addItem(NSMenuItem(title: "\(appName) Help", action: #selector(showHelp), keyEquivalent: "?"))
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc func showAPISettings() {
        statusBarController?.showAPISettings()
    }
    
    @objc func showAbout() {
        statusBarController?.showAbout()
    }
    
    @objc func showHelp() {
        statusBarController?.showHelp()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("Application became active")
    }
    
}
