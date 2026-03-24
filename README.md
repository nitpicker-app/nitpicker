<div align="center">
   <img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="150" />
   <h1>Nitpicker</h1>
</div>

A macOS menubar application that helps you correct grammar in any text on your Mac. Nitpicker uses cloud-based AI services (OpenAI) to provide high-quality grammar corrections directly from your menubar.

## Features

- 🔤 Grammar correction for any selected text across macOS
- 🎤 Real-time voice dictation with streaming transcription
- 🚀 Fast correction with keyboard shortcuts
  - Cmd+Shift+B for grammar correction
  - Cmd+Shift+D for voice dictation
- 🧠 AI-powered using OpenAI's GPT models
- 🔒 Privacy-focused: Local API key storage
- 👻 Unobtrusive menubar-only interface

## Requirements

- macOS 13.5 or later
- Xcode 14.0+ (for development)
- An OpenAI API key

## Installation

1. Download the latest release from the [Releases](https://github.com/nitpicker-app/nitpicker/releases) page.
2. Move Nitpicker.app to your Applications folder.
3. Launch Nitpicker.
4. Add your OpenAI API key in the settings.

## Usage

### First Launch

1. Launch Nitpicker.
2. Grant accessibility permissions when prompted (required to read and replace text).
3. Click on the text cursor icon in the menubar.
4. Select "API Settings" and enter your OpenAI API key.

### Correcting Text

1. Select text in any application.
2. Press `Cmd+Shift+B` or click the menubar icon and select "Correct Selected Text."
3. Wait for the correction to complete.
4. The corrected text will automatically replace the selected text.

### Voice Dictation

## Accessibility Permissions

Nitpicker requires accessibility permissions to:
- Read text you've selected.
- Replace text with corrected versions.
- Paste transcribed text from dictation.

Nitpicker also requires microphone permissions for voice dictation.

You can grant these permissions in System Settings → Privacy & Security → Accessibility and Microphone.
## Accessibility Permissions

Nitpicker requires accessibility permissions to:
- Read text you've selected.
- Replace text with corrected versions.

You can grant these permissions in System Settings → Privacy & Security → Accessibility.

## Development

### Project Structure
### Dependencies

- [HotKey](https://github.com/soffes/HotKey): Global keyboard shortcut handling.
- [FluidAudio](https://github.com/FluidInference/FluidAudio): On-device streaming speech recognition.
- **Helpers/**: Utility classes for accessibility and clipboard operations.
- **Services/**: 
  - **OpenAIService.swift**: Cloud-based AI text correction.
  - **TextCorrectionServiceFactory.swift**: Service management.
- **Views/**: SwiftUI views for settings and UI.
- **Models/**: Data models.

### Dependencies

- [HotKey](https://github.com/soffes/HotKey): Global keyboard shortcut handling.

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/nitpicker-app/nitpicker.git
## Privacy

Nitpicker stores your API key locally in the Keychain and only sends the selected text to OpenAI's API for grammar correction. Voice dictation is processed entirely on-device using FluidAudio - no audio is sent to external servers. No other data is collected or transmitted.

## Latest Updates

### v1.1 - December 2025
- ✨ **New**: Real-time voice dictation with streaming transcription (Cmd+Shift+D).
- 🎤 **New**: On-device speech recognition using FluidAudio.
- 🔧 **Improved**: Enhanced hotkey management supporting multiple shortcuts.

### v1.0 - July 2025
- ✨ **New**: AI-powered grammar correction using OpenAI.
- 🔧 **Improved**: Enhanced prompt engineering for better corrections.
- 🔧 **Improved**: Better window management and UI consistency.
- 🛡️ **Security**: Migrated API key storage from UserDefaults to Keychain.
- 🚀 **Performance**: Optimized text correction workflow.
- 📱 **UX**: Updated app icon and status bar interface.er corrections.
- 🔧 **Improved**: Better window management and UI consistency.
- 🛡️ **Security**: Migrated API key storage from UserDefaults to Keychain.
- 🚀 **Performance**: Optimized text correction workflow.
- 📱 **UX**: Updated app icon and status bar interface.

## License

MIT © Vishnu R