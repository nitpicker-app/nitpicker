import Cocoa
import SwiftUI

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let popover = NSPopover()
    private let contentViewModel: ContentViewModel
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var eventMonitor: Any?

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
        popover.behavior = .applicationDefined
        popover.animates = true
        let contentView = ContentView(viewModel: contentViewModel, onOpenSettings: { [weak self] in
            self?.openSettings()
        }, onOpenHelp: { [weak self] in
            self?.openHelp()
        })
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
            closePopover()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.collectionBehavior = [
                .canJoinAllSpaces, .fullScreenAuxiliary
            ]
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
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

        let helpItem = NSMenuItem(
            title: "Help",
            action: #selector(openHelp),
            keyEquivalent: ""
        )
        helpItem.target = self
        menu.addItem(helpItem)

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
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 440),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: APISettingsView())
        window.setContentSize(NSSize(width: 380, height: 440))
        window.minSize = NSSize(width: 360, height: 360)
        window.center()

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openHelp() {
        if let window = helpWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nitpicker Help"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: HelpView())
        window.setContentSize(NSSize(width: 420, height: 520))
        window.center()

        helpWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
