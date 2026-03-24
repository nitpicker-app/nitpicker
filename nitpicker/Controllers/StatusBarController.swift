import Cocoa
import SwiftUI

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let popover = NSPopover()
    private let contentViewModel: ContentViewModel
    private var settingsWindow: NSWindow?

    init(viewModel: ContentViewModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.contentViewModel = viewModel
        super.init()
        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.image = NSImage(
            systemSymbolName: "character.cursor.ibeam",
            accessibilityDescription: "Nitpicker"
        )?.withSymbolConfiguration(config)
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.animates = true
        let contentView = ContentView(viewModel: contentViewModel) { [weak self] in
            self?.openSettings()
        }
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Context menu (right-click)

    private func showContextMenu() {
        let menu = NSMenu()

        let correctItem = NSMenuItem(
            title: "Correct Selected Text",
            action: #selector(correctText),
            keyEquivalent: ""
        )
        correctItem.target = self
        menu.addItem(correctItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(
            title: "About Nitpicker",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Nitpicker",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.popUpMenu(menu)
    }

    // MARK: - Actions

    @objc private func correctText() {
        contentViewModel.correctSelectedText()
    }

    @objc func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: APISettingsView())
        window.setContentSize(NSSize(width: 360, height: 280))
        window.center()

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
