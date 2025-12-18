<div align="center">
   <img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="150" />
   <h1>Nitpicker</h1>
</div>

A macOS menubar application that helps you correct grammar in any text on your Mac. Nitpicker uses cloud-based AI services (OpenAI) to provide high-quality grammar corrections directly from your menubar.

## Features

- 🔤 Grammar correction for any selected text across macOS
- 🎤 Voice dictation with local AI-powered transcription
- 🚀 Fast correction with keyboard shortcuts
  - `Cmd+Shift+B` - Correct selected text
  - `Cmd+Shift+D` - Start/stop voice dictation
- 🧠 AI-powered using OpenAI's GPT models and FluidAudio
- 🔒 Privacy-focused: Local API key storage and on-device transcription
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

1. Press `Cmd+Shift+D` or click the "Start Dictation" button in the menubar.
2. Speak your text into the microphone.
3. Press `Cmd+Shift+D` again to stop recording.
4. Wait for transcription and grammar correction.
5. The corrected text will be automatically pasted.

Nitpicker uses:
- OpenAI's GPT-4o-mini for grammar corrections (requires internet)
- FluidAudio's Parakeet ASR for local, private speech-to-text (works offline)

## Accessibility Permissions

Nitpicker requires the following permissions:
- **Accessibility**: To read and replace text you've selected.
- **Microphone**: For voice dictation (optional).

You can grant these permissions in System Settings → Privacy & Security.

## Development

### Project Structure

- **AppDelegate.swift**: Main application delegate with auto-launch support.
- **StatusBarController.swift**: Controls the menubar UI and interactions.
- **Helpers/**: Utility classes for accessibility and clipboard operations.
- **Services/**: 
  - **OpenAIService.swift**: Cloud-based AI text correction.
  - **DictationService.swift**: Voice recording and transcription using FluidAudio.
  - **TextCorrectionServiceFactory.swift**: Service management.
- **Views/**: SwiftUI views for settings and UI.
- **Models/**: Data models.

### Dependencies

- [HotKey](https://github.com/soffes/HotKey): Global keyboard shortcut handling.
- [FluidAudio](https://github.com/FluidInference/FluidAudio): Local speech recognition and transcription.

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/nitpicker-app/nitpicker.git
   ```
2. Open `nitpicker.xcodeproj` in Xcode.
3. Build and run the project (`Cmd+R`).

## Privacy

Nitpicker prioritizes your privacy:
- API key is stored locally in the Keychain
- Only selected text is sent to OpenAI's API for correction
- Voice dictation is processed entirely on-device using FluidAudio
- No audio recordings are stored or transmitted
- No usage data is collected or transmitted

## Latest Updates

### v1.0 - July 2025
- ✨ **New**: AI-powered grammar correction using OpenAI.
- 🔧 **Improved**: Enhanced prompt engineering for better corrections.
- 🔧 **Improved**: Better window management and UI consistency.
- 🛡️ **Security**: Migrated API key storage from UserDefaults to Keychain.
- 🚀 **Performance**: Optimized text correction workflow.
- 📱 **UX**: Updated app icon and status bar interface.

## License

MIT © Vishnu R