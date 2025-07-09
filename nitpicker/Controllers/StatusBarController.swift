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
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        self.contentViewModel = contentView.viewModel

        super.init()

        setupStatusBarButton()
        setupPopover(with: contentView)
        setupMenu()
    }

    // MARK: - Setup Methods

    private func setupStatusBarButton() {
        if let button = statusItem.button {
            // Create the image with a specific symbol configuration for proper sizing
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            button.image = NSImage(
                systemSymbolName: "character.cursor.ibeam", 
                accessibilityDescription: nil
            )?.withSymbolConfiguration(config)
            
            // Ensure the image is properly sized and positioned in the status bar
            button.image?.size = NSSize(width: 16, height: 16)
            button.imagePosition = .imageLeft
            button.action = #selector(handleStatusItemClick)
        }
    }

    private func setupPopover(with contentView: ContentView) {
        popover.contentSize = NSSize(width: 300, height: 150)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: contentView
        )
    }

    private func setupMenu() {
        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(
                title: "Press Cmd + Shift + B to correct text",
                action: nil,
                keyEquivalent: ""
            )
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "API Settings",
                action: #selector(showAPISettings),
                keyEquivalent: ","
            )
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "About Nitpicker",
                action: #selector(showAbout),
                keyEquivalent: ""
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "Help",
                action: #selector(showHelp),
                keyEquivalent: "?"
            )
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        statusItem.menu = menu
    }

    // MARK: - Window Creation

    private func createStyledWindow(
        width: CGFloat,
        height: CGFloat,
        contentView: NSViewController
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.hasShadow = true
        window.contentViewController = contentView
        window.center()
        window.delegate = self

        return window
    }

    private func createAndShowWindow<T: View>(
        size: NSSize,
        rootView: T,
        windowController: inout NSWindowController?
    ) {
        let hostingController = NSHostingController(rootView: rootView)
        let window = createStyledWindow(
            width: size.width,
            height: size.height,
            contentView: hostingController
        )
        windowController = NSWindowController(window: window)
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Action Handlers

    @objc func showAPISettings() {
        if apiSettingsWindowController == nil {
            let apiKeyView = APISettingsView()
            createAndShowWindow(
                size: NSSize(width: 340, height: 320),
                rootView: apiKeyView,
                windowController: &apiSettingsWindowController
            )
        } else {
            apiSettingsWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if let event = NSApp.currentEvent {
            // Show menu on right click or control+click
            if event.type == .rightMouseUp
                || (event.type == .leftMouseUp
                    && event.modifierFlags.contains(.control))
            {
                statusItem.menu?.popUp(
                    positioning: nil,
                    at: NSEvent.mouseLocation,
                    in: nil
                )
                return
            }
        }

        // Show status on left click
        statusItem.menu?.popUp(
            positioning: nil,
            at: NSEvent.mouseLocation,
            in: nil
        )
    }

    @objc private func correctSelectedText() {
        contentViewModel.correctSelectedText()
    }

    @objc func showAbout() {
        if aboutWindowController == nil {
            let about = AboutView()
            createAndShowWindow(
                size: NSSize(width: 340, height: 320),
                rootView: about,
                windowController: &aboutWindowController
            )
        } else {
            aboutWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func showHelp() {
        if helpWindowController == nil {
            let helpContent = HelpView()
            createAndShowWindow(
                size: NSSize(width: 400, height: 380),
                rootView: helpContent,
                windowController: &helpWindowController
            )

            // Set window as movable if needed
            helpWindowController?.window?.isMovableByWindowBackground = true
        } else {
            helpWindowController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
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
