

<div align="center">
   <img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="150" />
   <h1>Nitpicker</h1>
</div>

A macOS menubar application that helps you correct grammar in any text on your Mac. Nitpicker supports both cloud-based AI services (OpenAI) and local AI models (Ollama) to provide high-quality grammar corrections directly from your menubar.


## Features

- 🔤 Grammar correction for any selected text across macOS
- 🚀 Fast correction with keyboard shortcut (Cmd+Shift+B)
- 🧠 Dual AI support: OpenAI's cloud models or local Ollama models
- 🔒 Privacy-focused: Local API key storage or completely offline with Ollama
- 👻 Unobtrusive menubar-only interface
- ⚡ Service switching: Choose between cloud and local AI processing

## Requirements

- macOS 13.5 or later
- Xcode 14.0+ (for development)
- Either:
  - An OpenAI API key (for cloud-based corrections), or
  - Ollama installed locally (for offline corrections)

## Installation

1. Download the latest release from the [Releases](https://github.com/nitpicker-app/nitpicker/releases) page
2. Move Nitpicker.app to your Applications folder
3. Launch Nitpicker
4. Add your OpenAI API key in the settings

## Usage

### First Launch

1. Launch Nitpicker
2. Grant accessibility permissions when prompted (required to read and replace text)
3. Click on the text cursor icon in the menubar
4. Select "API Settings" and enter your OpenAI API key (for cloud-based corrections)

### Setting up Ollama (Optional - for local processing)

1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Start Ollama service: `ollama serve`
3. Pull the required model: `ollama pull gemma3n:e2b`
4. Nitpicker will automatically use Ollama when available and configured

### Correcting Text

1. Select text in any application
2. Press `Cmd+Shift+B` or click the menubar icon and select "Correct Selected Text"
3. Wait for the correction to complete
4. The corrected text will automatically replace the selected text

### AI Service Options

#### OpenAI (Cloud-based)
- Requires an OpenAI API key
- Uses GPT-4o-mini model for fast, accurate corrections
- Requires internet connection

#### Ollama (Local)
- Completely offline processing
- Uses Gemma 3n:e2b model by default
- Requires Ollama to be installed and running locally
- No API key needed
- Better privacy as text never leaves your machine

## Accessibility Permissions

Nitpicker requires accessibility permissions to:
- Read text you've selected
- Replace text with corrected versions

You can grant these permissions in System Settings → Privacy & Security → Accessibility.

## Development

### Project Structure

- **AppDelegate.swift**: Main application delegate with auto-launch support
- **StatusBarController.swift**: Controls the menubar UI and interactions
- **Helpers/**: Utility classes for accessibility and clipboard operations
- **Services/**: 
  - **OpenAIService.swift**: Cloud-based AI text correction
  - **OllamaService.swift**: Local AI text correction using Ollama
  - **TextCorrectionServiceFactory.swift**: Service management and switching
- **Views/**: SwiftUI views for settings and UI
- **Models/**: Data models

### Dependencies

- [HotKey](https://github.com/soffes/HotKey): Global keyboard shortcut handling
- [ollama-swift](https://github.com/loopwork/ollama-swift): Local AI model integration

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/nitpicker-app/nitpicker.git
   ```
2. Open `nitpicker.xcodeproj` in Xcode
3. Build and run the project (`Cmd+R`)

## Privacy

### OpenAI Service
- Stores your API key locally in the Keychain (not UserDefaults)
- Only sends the selected text to OpenAI's API for correction
- Does not collect or transmit any other data

### Ollama Service
- Completely offline processing
- No data leaves your machine
- No API keys required
- Text is processed locally using your own hardware

## Latest Updates

### v1.0 - July 2025
- ✨ **New**: Added support for local AI processing with Ollama
- ✨ **New**: Service factory pattern for easy switching between AI providers
- 🔧 **Improved**: Enhanced prompt engineering for both OpenAI and Ollama services
- 🔧 **Improved**: Better window management and UI consistency
- 🛡️ **Security**: Migrated API key storage from UserDefaults to Keychain
- 🚀 **Performance**: Optimized text correction workflow
- 📱 **UX**: Updated app icon and status bar interface

## License

MIT © Vishnu R
