//
//  StatusBarController.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//


import Cocoa
import SwiftUI

class StatusBarController: NSObject, NSWindowDelegate {
    private var statusItem: NSStatusItem
    private var popover = NSPopover()
    var apiSettingsWindowController: NSWindowController?
    var aboutWindowController: NSWindowController?
    var helpWindowController: NSWindowController?
    private var contentViewModel: ContentViewModel
    
    init(contentView: ContentView) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.contentViewModel = contentView.viewModel
        
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: nil)
            // We'll use rightMouseUp for the menu
            button.action = #selector(handleStatusItemClick)
        }

        popover.contentSize = NSSize(width: 300, height: 150)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(title: "API Settings", action: #selector(showAPISettings), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        // About and Help
        menu.addItem(NSMenuItem(title: "About Nitpicker", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Help", action: #selector(showHelp), keyEquivalent: "?"))
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func showAPISettings() {
        if apiSettingsWindowController == nil {
            let apiKeyView = APIKeyView()
            let hostingController = NSHostingController(rootView: apiKeyView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "API Settings"
            window.contentViewController = hostingController
            window.center()
            
            apiSettingsWindowController = NSWindowController(window: window)
            
            // Set delegate to handle window close events
            window.delegate = self
        }
        
        apiSettingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if let event = NSApp.currentEvent {
            // Show menu on right click or control+click
            if event.type == .rightMouseUp || (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
                statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
                return
            }
        }
        
        // Show status on left click
        statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc private func correctSelectedText() {
        contentViewModel.correctSelectedText()
    }
    
    @objc func showAbout() {
        if aboutWindowController == nil {
            let aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            let aboutView = NSHostingController(rootView: 
                VStack(spacing: 12) {
                    Text("Nitpicker")
                        .font(.title)
                        .bold()
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                    
                    Text("© 2025 Vishnu R")
                        .font(.caption)
                    
                    Text("A grammar correction app that helps you fix text anywhere on your Mac.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 280)
                }
                .padding()
            )
            
            aboutWindow.title = "About Nitpicker"
            aboutWindow.contentViewController = aboutView
            aboutWindow.center()
            
            // Create and retain the window controller
            aboutWindowController = NSWindowController(window: aboutWindow)
            
            // Set delegate to handle window close events
            aboutWindow.delegate = self
        }
        
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showHelp() {
        if helpWindowController == nil {
            let helpWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            let helpView = NSHostingController(rootView: 
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nitpicker Help")
                        .font(.title)
                        .bold()
                    
                    Group {
                        Text("How to Use").bold()
                        
                        Text("1. Select text anywhere in macOS")
                        Text("2. Press Cmd+Shift+G or use the menu option")
                        Text("3. Nitpicker will correct the grammar and replace the text")
                    }
                    
                    Group {
                        Text("API Settings").bold()
                        
                        Text("Nitpicker uses OpenAI's API to correct grammar. You need to provide your own API key in the settings.")
                    }
                    
                    Group {
                        Text("Accessibility").bold()
                        
                        Text("The app requires accessibility permissions to read and replace text. You can grant these in System Settings → Privacy & Security → Accessibility.")
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            )
            
            helpWindow.title = "Nitpicker Help"
            helpWindow.contentViewController = helpView
            helpWindow.center()
            
            // Create and retain the window controller
            helpWindowController = NSWindowController(window: helpWindow)
            
            // Set delegate to handle window close events
            helpWindow.delegate = self
        }
        
        helpWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Determine which window is closing and clean up accordingly
        if window == aboutWindowController?.window {
            aboutWindowController = nil
        } else if window == helpWindowController?.window {
            helpWindowController = nil
        } else if window == apiSettingsWindowController?.window {
            apiSettingsWindowController = nil
        }
    }
}
