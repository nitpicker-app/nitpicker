# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project. Build and run using Xcode or `xcodebuild`:

```bash
# Build
xcodebuild -project nitpicker.xcodeproj -scheme nitpicker -configuration Debug build

# Run tests
xcodebuild test -project nitpicker.xcodeproj -scheme nitpicker -destination 'platform=macOS'

# Run a single test
xcodebuild test -project nitpicker.xcodeproj -scheme nitpicker -destination 'platform=macOS' -only-testing:nitpickerTests/nitpickerTests/testName
```

The app requires macOS 14.6+ (deployment target in project settings). Open `nitpicker.xcodeproj` in Xcode 16+ to develop interactively.

The project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 feature) — adding or deleting Swift files on disk is automatically reflected in the build; no `project.pbxproj` edits needed for individual source files.

## Architecture

Nitpicker is a macOS menubar-only app. Its sole feature is AI grammar correction: select text anywhere, press ⌘⇧B, and the corrected text is pasted back in place.

The app has `LSUIElement = true` and `LSBackgroundOnly = true` in `Info.plist`, making it a background-only process with no Dock icon. This means `NSApp` cannot be activated in the normal sense — any UI must be driven directly via `NSWindow`/`NSPopover`, not through SwiftUI scene mechanisms like `showSettingsWindow:`.

### Entry Point & Coordination

`nitpickerApp.swift` bootstraps via `@NSApplicationDelegateAdaptor`. `AppDelegate` is the root coordinator: on launch it checks accessibility permissions, creates `ContentViewModel`, wires up `StatusBarController`, and registers the ⌘⇧B hotkey via `HotKeyManager.shared` (backed by the `HotKey` SPM package).

### Grammar Correction Flow

1. ⌘⇧B → `HotKeyManager` fires → `ContentViewModel.correctSelectedText()`
2. `ClipboardHelper.copySelectedText()` simulates Cmd+C via `CGEvent` to capture the selected text
3. `TextCorrectionServiceFactory.current` (returns `OpenAIService.shared`) calls OpenAI's `gpt-4o-mini`
4. On completion, `ClipboardHelper.replaceSelectedText()` simulates Cmd+V to paste the result back
5. `ContentViewModel.correctionStatus` transitions: `.idle` → `.correcting` → `.done(corrected:)`, then resets to `.idle` after 5 seconds

`ClipboardHelper` uses raw `CGEvent` key simulation (virtual key 8 = C, 9 = V) with `usleep` delays — accessibility permissions are required.

### UI

**`StatusBarController`** owns the `NSStatusItem` and an `NSPopover`:
- Left-click → toggles the popover
- Right-click → context `NSMenu` (correct text, settings, about, quit)
- Settings window is managed manually via a private `NSWindow` — **do not** use `NSApp.sendAction(showSettingsWindow:)` as it won't work in a `LSBackgroundOnly` app

**`ContentView`** is the popover content. It is status-driven via `ContentViewModel.correctionStatus` and shows warnings if the API key is missing or accessibility permission is not granted. It receives an `onOpenSettings: () -> Void` closure from `StatusBarController` to open the settings window.

**`APISettingsView`** is the settings window content — a `Form` with `.formStyle(.grouped)` containing a Launch at Login toggle (`SMAppService`) and the OpenAI API key field.

About uses `NSApp.orderFrontStandardAboutPanel()` — no custom About view.

### Service Layer

- `TextCorrectionService` — protocol: `correctGrammar(text:completion:) async`
- `TextCorrectionServiceFactory` — returns the active service (currently always `OpenAIService`)
- `KeychainService` — stores/retrieves the OpenAI API key from the system Keychain
- `AccessibilityPermissionManager` — centralized permission check/request; used by `ClipboardHelper` and `ContentViewModel`

### Dependencies (SPM)

- **HotKey** — global keyboard shortcut registration
