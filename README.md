<div align="center">
   <img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="150" />
   <h1>Nitpicker</h1>
   <p>AI-powered text correction for any app on your Mac</p>
</div>

Nitpicker is a macOS menubar app that corrects and transforms selected text using OpenAI. Select any text, press ⌘⇧B, and the result is pasted back instantly — in any app.

## Features

- **Multiple correction modes** — Grammar, Formal, Concise, and Translate, switchable from the menubar popover
- **Custom modes** — define your own modes with a name and system prompt; they persist across sessions
- **Translate** — translate selected text to any of 13 languages with a single click
- **Correction history** — tap any history entry to expand a word-level diff showing exactly what changed
- **Global hotkey** — ⌘⇧B works in any app without switching focus
- **Privacy-first** — your API key is stored in the system Keychain; only the selected text is sent to OpenAI

## Requirements

- macOS 14.6 or later
- An OpenAI API key

## Installation

1. Download the latest release from the [Releases](https://github.com/nitpicker-app/nitpicker/releases) page.
2. Move `Nitpicker.app` to your Applications folder.
3. Launch Nitpicker and grant Accessibility permission when prompted.
4. Open Settings (⚙ in the popover) and enter your OpenAI API key.

## Usage

### Correcting text

1. Select text in any application.
2. Press `⌘⇧B`.
3. The corrected text replaces the selection automatically.

### Switching modes

Click the mode pill (e.g. `Grammar`) in the popover header to switch between built-in and custom modes. The active mode is remembered across launches.

### Translate

Switch to **Translate** mode and choose a target language from the dropdown that appears. Press `⌘⇧B` as usual.

### Custom modes

Open **Settings → Custom Modes → Add Mode**. Give it a name and a system prompt describing how the AI should transform the text. Custom modes appear in the mode picker immediately.

## Accessibility Permission

Nitpicker requires Accessibility permission to simulate Cmd+C and Cmd+V for reading and replacing selected text. Grant it in:

**System Settings → Privacy & Security → Accessibility**

## Privacy

Only the selected text is sent to OpenAI's API. Your API key is stored in the macOS Keychain and never leaves your device. No usage data or telemetry is collected.

## Development

Built with Swift and SwiftUI, targeting macOS 14.6+. Open `nitpicker.xcodeproj` in Xcode 16+.

**Dependencies**
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcut registration

**Build**
```bash
xcodebuild -project nitpicker.xcodeproj -scheme nitpicker -configuration Debug build
```

## License

MIT © Vishnu R
