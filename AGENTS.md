# AGENTS.md

## Project Overview

Nitpicker is a macOS menubar-only app (no Dock icon) for AI-powered text correction. Select text anywhere, press ⌘⇧B, and corrected text replaces the selection. See [CLAUDE.md](CLAUDE.md) for full architecture details.

## Build & Test

```bash
# Build
xcodebuild -project nitpicker.xcodeproj -scheme nitpicker -configuration Debug build

# Run all tests
xcodebuild test -project nitpicker.xcodeproj -scheme nitpicker -destination 'platform=macOS'

# Run a single test
xcodebuild test -project nitpicker.xcodeproj -scheme nitpicker -destination 'platform=macOS' -only-testing:nitpickerTests/nitpickerTests/testName
```

Requires Xcode 16+ and macOS 14.6+.

## File Sync

The project uses `PBXFileSystemSynchronizedRootGroup` — adding or deleting Swift files on disk is automatically reflected in the build. No `project.pbxproj` edits needed for source files.

## Code Conventions

- **Concurrency**: All UI classes (`AppDelegate`, `StatusBarController`, `ContentViewModel`) are `@MainActor`. Do not remove these annotations.
- **Async pattern**: Use completion handlers (not async/await) in the service layer for consistency. Use `DispatchQueue.main.async` for UI updates in callbacks.
- **State**: `@Published` properties + Combine for reactivity. `UserDefaults` for settings, Keychain for secrets.
- **Window management**: Manual `NSWindow`/`NSPopover` — no SwiftUI scene mechanisms (`showSettingsWindow:` won't work in `LSBackgroundOnly` apps).
- **Organization**: Use `// MARK: -` comments to divide files into logical sections.
- **Testing framework**: Swift Testing (`@Test func ...`), not XCTest.

## Architecture Constraints

- `LSUIElement = true` + `LSBackgroundOnly = true` — `NSApp` cannot be activated normally
- `ClipboardHelper` uses raw `CGEvent` key simulation — accessibility permissions required
- OpenAI Responses API (`/v1/responses`), not Chat Completions
- Single SPM dependency: [HotKey](https://github.com/soffes/HotKey) for global shortcut registration

## Common Pitfalls

- Do not use `NSApp.sendAction(Selector("showSettingsWindow:"))` — it silently fails in background-only apps
- `@State` re-renders are unreliable inside `NSPopover` windows — use `@StateObject` with `ObservableObject` instead
- `statusItem.menu` must be nil'd after use (set → performClick → nil pattern) to allow left-click popover to work
- Keychain passwords must be deleted before re-saving to avoid `errSecDuplicateItem`
