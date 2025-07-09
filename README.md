# Nitpicker

A macOS menubar application that helps you correct grammar in any text on your Mac. Nitpicker uses OpenAI's API to provide high-quality grammar corrections directly from your menubar.

<img src="https://github.com/user-attachments/assets/5b6a0af5-c0cc-4821-86b1-4fa2962da171" alt="Nitpicker Logo" width="300" />


## Features

- 🔤 Grammar correction for any selected text across macOS
- 🚀 Fast correction with keyboard shortcut (Cmd+Shift+G)
- 🧠 Powered by OpenAI's advanced language models
- 🔒 Local API key storage for privacy
- 👻 Unobtrusive menubar-only interface

## Requirements

- macOS 12.0 or later
- Xcode 14.0+ (for development)
- An OpenAI API key

## Installation

1. Download the latest release from the [Releases](https://github.com/yourusername/nitpicker/releases) page
2. Move Nitpicker.app to your Applications folder
3. Launch Nitpicker
4. Add your OpenAI API key in the settings

## Usage

### First Launch

1. Launch Nitpicker
2. Grant accessibility permissions when prompted (required to read and replace text)
3. Click on the hammer icon in the menubar
4. Select "API Settings" and enter your OpenAI API key

### Correcting Text

1. Select text in any application
2. Press `Cmd+Shift+G` or click the menubar icon and select "Correct Selected Text"
3. Wait for the correction to complete
4. The corrected text will automatically replace the selected text

## Accessibility Permissions

Nitpicker requires accessibility permissions to:
- Read text you've selected
- Replace text with corrected versions

You can grant these permissions in System Settings → Privacy & Security → Accessibility.

## Development

### Project Structure

- **AppDelegate.swift**: Main application delegate
- **StatusBarController.swift**: Controls the menubar UI and interactions
- **Helpers/**: Utility classes for accessibility and clipboard operations
- **Services/**: OpenAI API integration
- **Views/**: SwiftUI views for settings and UI
- **Models/**: Data models

### Building from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/nitpicker.git
   ```
2. Open `nitpicker.xcodeproj` in Xcode
3. Build and run the project (`Cmd+R`)

## Privacy

Nitpicker:
- Stores your API key locally in UserDefaults
- Only sends the selected text to OpenAI's API for correction
- Does not collect or transmit any other data

## License

MIT © Vishnu R
