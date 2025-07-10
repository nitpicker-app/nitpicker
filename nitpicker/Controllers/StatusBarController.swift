import Cocoa
import SwiftUI

class StatusBarController: NSObject, NSWindowDelegate {
    private var statusItem: NSStatusItem
    private var popover = NSPopover()
    private var mainWindowController: NSWindowController?
    private var contentViewModel: ContentViewModel
    
    // Current view type to track which view is active
    enum ViewType {
        case apiSettings
        case about
        case help
    }
    
    private var currentViewType: ViewType?

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
        height: CGFloat
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isOpaque = true
        window.hasShadow = true
        window.center()
        window.delegate = self

        return window
    }
    
    private func showMainWindow(viewType: ViewType) {
        // Create window if it doesn't exist or show existing window
        if mainWindowController == nil {
            let window = createStyledWindow(width: 400, height: 380)
            mainWindowController = NSWindowController(window: window)
        }
        
        // Update content based on selection
        updateWindowContent(for: viewType)
        
        // Show window and focus app
        mainWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func updateWindowContent(for viewType: ViewType) {
        guard let window = mainWindowController?.window else { return }
        
        // Create appropriate view based on selection
        let hostingController: NSHostingController<AnyView>
        
        switch viewType {
        case .apiSettings:
            hostingController = NSHostingController(rootView: AnyView(APISettingsView()))
            window.setContentSize(NSSize(width: 340, height: 320))
        case .about:
            hostingController = NSHostingController(rootView: AnyView(AboutView()))
            window.setContentSize(NSSize(width: 340, height: 320))
        case .help:
            hostingController = NSHostingController(rootView: AnyView(HelpView()))
            window.setContentSize(NSSize(width: 400, height: 380))
        }
        
        // Update current view type
        self.currentViewType = viewType
        
        // Update window content
        window.contentViewController = hostingController
    }

    // MARK: - Action Handlers

    @objc func showAPISettings() {
        showMainWindow(viewType: .apiSettings)
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
        showMainWindow(viewType: .about)
    }

    @objc func showHelp() {
        showMainWindow(viewType: .help)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Reset window controller when window is closed
        if window == mainWindowController?.window {
            mainWindowController = nil
        }
    }
}
