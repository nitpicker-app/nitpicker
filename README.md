<div align="center">
   <img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="150" />
   <h1>Nitpicker</h1>
</div>

A macOS menubar application that helps you correct grammar in any text on your Mac. Nitpicker uses cloud-based AI services (OpenAI) to provide high-quality grammar corrections directly from your menubar.

## Features

- 🔤 Grammar correction for any selected text across macOS
- 📸 Context-aware corrections using screenshot analysis
- 🚀 Fast correction with a keyboard shortcut (Cmd+Shift+B)
- 🧠 AI-powered using OpenAI's GPT models with vision capabilities
- 🔒 Privacy-focused: Local API key storage
- 👻 Unobtrusive menubar-only interface

## Requirements

- macOS 14.0 or later
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
3. Grant screen recording permissions when prompted (required to capture context for better corrections).
4. Click on the text cursor icon in the menubar.
5. Select "API Settings" and enter your OpenAI API key.

### Correcting Text

1. Select text in any application.
2. Press `Cmd+Shift+B` or click the menubar icon and select "Correct Selected Text."
3. Nitpicker will capture a screenshot of your active screen for context (e.g., to understand if you're writing an email, code comment, document, etc.).
4. Wait for the correction to complete.
5. The corrected text will automatically replace the selected text.

Nitpicker uses OpenAI's GPT-4o-mini model with vision capabilities for context-aware, accurate corrections and requires an internet connection.

## Accessibility Permissions

Nitpicker requires accessibility permissions to:
- Read text you've selected.
- Replace text with corrected versions.

Nitpicker requires screen recording permissions to:
- Capture screenshots of your active screen for context analysis.
- Understand the application context (email, document, code, chat, etc.) to provide more accurate, contextually appropriate corrections.

You can grant these permissions in System Settings → Privacy & Security → Accessibility and Screen Recording.

## Development

### Project Structure

- **AppDelegate.swift**: Main application delegate with auto-launch support.
- **StatusBarController.swift**: Controls the menubar UI and interactions.
- **Helpers/**: Utility classes for accessibility and clipboard operations.
- **Services/**: 
  - **OpenAIService.swift**: Cloud-based AI text correction with vision support.
  - **TextCorrectionServiceFactory.swift**: Service management.
- **Views/**: SwiftUI views for settings and UI.
- **Models/**: Data models.

### Dependencies

- [HotKey](https://github.com/soffes/HotKey): Global keyboard shortcut handling.

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/nitpicker-app/nitpicker.git
   ```
2. Open `nitpicker.xcodeproj` in Xcode.
3. Build and run the project (`Cmd+R`).

## Privacy

Nitpicker stores your API key locally in the Keychain and only sends the selected text and a screenshot of your active screen to OpenAI's API for context-aware correction. Screenshots are captured temporarily and are not stored locally. No other data is collected or transmitted.

## Latest Updates

### v1.1 - November 2025
- 📸 **New**: Context-aware corrections using screenshot analysis
- 🤖 **New**: Visual understanding of where text is being used (emails, documents, code, etc.)
- 🎯 **Improved**: More accurate corrections based on application context
- 🔐 **Privacy**: Temporary screenshot capture with no local storage

### v1.0 - July 2025
- ✨ **New**: AI-powered grammar correction using OpenAI.
- 🔧 **Improved**: Enhanced prompt engineering for better corrections.
- 🔧 **Improved**: Better window management and UI consistency.
- 🛡️ **Security**: Migrated API key storage from UserDefaults to Keychain.
- 🚀 **Performance**: Optimized text correction workflow.
- 📱 **UX**: Updated app icon and status bar interface.

## License

MIT © Vishnu R