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

Nitpicker is a macOS menubar-only app. Its core feature is AI text correction: select text anywhere, press ⌘⇧B, and the corrected text is pasted back in place. Multiple correction modes are supported (Grammar, Formal, Concise, Translate, and custom user-defined modes).

The app has `LSUIElement = true` and `LSBackgroundOnly = true` in `Info.plist`, making it a background-only process with no Dock icon. This means `NSApp` cannot be activated in the normal sense — any UI must be driven directly via `NSWindow`/`NSPopover`, not through SwiftUI scene mechanisms like `showSettingsWindow:`.

### Concurrency

`AppDelegate`, `StatusBarController`, and `ContentViewModel` are all marked `@MainActor`. All UI and state mutations happen on the main actor. Do not remove these annotations — they resolve Swift concurrency warnings and are architecturally correct since all three classes are always used on the main thread.

### Entry Point & Coordination

`nitpickerApp.swift` bootstraps via `@NSApplicationDelegateAdaptor`. `AppDelegate` is the root coordinator: on launch it checks accessibility permissions, creates `ContentViewModel`, wires up `StatusBarController`, and registers the ⌘⇧B hotkey via `HotKeyManager.shared` (backed by the `HotKey` SPM package).

### Grammar Correction Flow

1. ⌘⇧B → `HotKeyManager` fires → `ContentViewModel.correctSelectedText()`
2. `ClipboardHelper.copySelectedText()` simulates Cmd+C via `CGEvent` to capture the selected text
3. `TextCorrectionServiceFactory.current` (returns `OpenAIService.shared`) calls OpenAI's Responses API (`/v1/responses`) with the user-selected model (stored in `UserDefaults` key `selectedModel`, defaulting to `gpt-5.4-mini`)
4. On completion, `ClipboardHelper.replaceSelectedText()` simulates Cmd+V to paste the result back
5. `ContentViewModel.correctionStatus` transitions: `.idle` → `.correcting` → `.done(corrected:)` (resets after 5s) or `.failed` (resets after 4s)
6. Successful corrections are prepended to `ContentViewModel.history` (capped at 10 entries, persisted to `UserDefaults` as JSON)

`ClipboardHelper` uses raw `CGEvent` key simulation (virtual key 8 = C, 9 = V) with `usleep` delays — accessibility permissions are required.

### Modes

`ModeManager.shared` manages correction modes. Built-in modes: Grammar, Formal, Concise, Translate. Users can add custom modes with a name and system prompt. The active mode ID is persisted in `UserDefaults` (`activeModeID`). Custom modes are persisted as JSON in `UserDefaults` (`customModes`). For the Translate mode, `ModeManager.effectiveSystemPrompt` generates the prompt dynamically based on `translateTargetLanguage`.

### UI

**`StatusBarController`** owns the `NSStatusItem` and an `NSPopover`:
- Left-click → toggles the popover
- Right-click → context `NSMenu` built dynamically; uses `statusItem.menu` + `performClick` + `statusItem.menu = nil` pattern (not the deprecated `popUpMenu`)
- Popover calls `popoverWindow.makeKey()` after showing to ensure SwiftUI `@StateObject` / `@ObservedObject` re-renders fire correctly inside the popover window
- Opening Settings or Help closes the popover first
- Settings and Help windows are managed manually via private `NSWindow` instances — **do not** use `NSApp.sendAction(showSettingsWindow:)` as it won't work in a `LSBackgroundOnly` app
- Status bar icon animates: pulsing ellipsis while correcting, checkmark on success, xmark on failure

**`ContentView`** is the popover content (280pt wide):
- Header: app name + mode picker menu + gear (settings)
- Translate mode shows a language picker row below the header
- Main area: empty state (shortcut hint or warnings) or scrollable history list (max 320pt tall)
- History rows: diff-attributed text (red strikethrough = deleted, green = inserted), click to copy corrected text, hover reveals copy icon, `.help()` tooltip shows original text, right-click context menu for copy options
- Footer: "Clear" (left, only when history is non-empty) + "Help" (right)
- Uses `HistoryState: ObservableObject` (`@StateObject`) for `copiedID` and `hoveredID` — must be `ObservableObject`, not `@State`, because `@State` re-renders are unreliable inside `NSPopover` windows

**`APISettingsView`** is the settings window content — a `Form` with `.formStyle(.grouped)`:
- General: Launch at Login toggle (`SMAppService`)
- AI Model: model picker (auto-saves to `UserDefaults`)
- OpenAI API Key: `SecureField` that auto-saves to Keychain on Return or focus loss; save status shown in section footer
- Custom Modes: list of user-defined modes with edit/delete; "Add Mode" opens `ModeEditView` sheet

**`HelpView`** is a scrollable help document shown in a separate `NSWindow`.

About uses `NSApp.orderFrontStandardAboutPanel()` — no custom About view.

### Service Layer

- `TextCorrectionService` — protocol: `correctGrammar(text:completion:) async`
- `TextCorrectionServiceFactory` — returns the active service (currently always `OpenAIService`)
- `KeychainService` — stores/retrieves the OpenAI API key from the system Keychain
- `AccessibilityPermissionManager` — centralized permission check/request; used by `ClipboardHelper` and `ContentViewModel`

### Dependencies (SPM)

- **HotKey** — global keyboard shortcut registration

## Code Conventions

- **Async pattern**: Service layer uses completion handlers (not `async`/`await`) for consistency with `URLSession.dataTask`. Use `DispatchQueue.main.async` for UI updates inside callbacks.
- **State**: `@Published` + Combine for reactivity; `UserDefaults` for settings; Keychain for secrets.
- **Testing**: Uses Swift Testing (`import Testing`, `@Test func ...`), **not** XCTest.
- **Organization**: Use `// MARK: -` to divide files into logical sections.

## Common Pitfalls

- **`NSApp.sendAction(Selector("showSettingsWindow:"))`** silently fails in `LSBackgroundOnly` apps — use the manual `NSWindow` pattern in `StatusBarController` instead.
- **`@State` in popovers**: Re-renders are unreliable inside `NSPopover` windows — use `@StateObject` with `ObservableObject` (see `HistoryState`).
- **`statusItem.menu` lifecycle**: Must be `nil`'d after use (`set → performClick → nil`) to prevent it from intercepting left-click and breaking the popover toggle.
- **Keychain duplicates**: Delete the existing item before re-saving to avoid `errSecDuplicateItem` errors.
