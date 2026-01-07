# Type None

Real-time audio to text transcription engine, accessible anywhere through a simple key binding.

<img src="https://img.shields.io/badge/Platform-macOS%2014%2B-blue" alt="Platform"> <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift"> <img src="https://img.shields.io/badge/License-MIT-green" alt="License">

## Features

- 🎤 **Real-time Transcription** - Speak and see your words appear instantly
- ⌨️ **Global Hotkey** - Access from any app with `⌥ + Space` (Option + Space)
- 🔒 **100% Local** - All processing happens on your Mac, no data leaves your device
- 🚀 **Powered by Whisper** - State-of-the-art speech recognition using whisper.cpp
- 🎨 **Beautiful UI** - Native macOS menu bar app with translucent floating overlay
- ⚡ **Optimized for Apple Silicon** - Takes full advantage of M-series Neural Engine

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (M1/M2/M3/M4) recommended for best performance
- ~2GB storage for the Whisper model

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/ritam/type-none.git
cd type-none/TypeNone
```

2. Build with Swift Package Manager:
```bash
swift build -c release
```

3. Run the app:
```bash
.build/release/TypeNone
```

### Opening in Xcode

1. Open the `TypeNone` folder in Xcode
2. File → Open → Select `Package.swift`
3. Build and Run (⌘R)

## Usage

1. **Launch the app** - Type None appears as an icon in your menu bar
2. **Grant permissions** - Allow microphone access when prompted
3. **Press and hold `⌥ + Space`** - A floating overlay appears and recording begins
4. **Speak** - Watch the waveform animate as you talk
5. **Release the keys** - Your speech is transcribed and copied to clipboard
6. **The text is automatically pasted** into your currently focused text field

### Menu Bar

Click the menu bar icon to:
- View recent transcriptions
- Access settings
- Check model loading status

### Settings

Access preferences via the menu bar or `⌘,`:
- **Hotkey** - Customize the activation shortcut
- **Auto-paste** - Toggle automatic pasting to active text field
- **Model** - Select Whisper model size (tiny/small/medium/large-turbo)
- **Audio Device** - Choose your preferred microphone

## Architecture

```
TypeNone/
├── Sources/
│   ├── App/
│   │   ├── TypeNoneApp.swift      # App entry point with MenuBarExtra
│   │   └── AppState.swift         # Global state management
│   ├── Services/
│   │   ├── AudioManager.swift     # AVAudioEngine microphone capture
│   │   ├── HotkeyManager.swift    # Global keyboard shortcuts
│   │   ├── TranscriptionService.swift  # Whisper integration
│   │   └── ClipboardService.swift # Clipboard & paste operations
│   └── Views/
│       ├── MenuBarView.swift      # Menu bar dropdown UI
│       ├── FloatingOverlay.swift  # Transcription overlay window
│       ├── SettingsView.swift     # Preferences panel
│       └── WaveformView.swift     # Audio visualization
├── Tests/
│   └── TypeNoneTests.swift        # Unit tests
└── Package.swift                  # Dependencies
```

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) - Global keyboard shortcuts
- [whisper.spm](https://github.com/ggerganov/whisper.spm) - Whisper.cpp Swift bindings

## Performance

On Apple Silicon Macs:
| Model | Speed | Accuracy | RAM |
|-------|-------|----------|-----|
| Tiny | 27x real-time | Good | ~200MB |
| Small | 7x real-time | Better | ~500MB |
| Medium | 3-4x real-time | High | ~1.5GB |
| Large Turbo | 5-8x real-time | Highest | ~2GB |

*Recommended: Large Turbo for M4 Pro with 24GB RAM*

## Privacy

Type None processes all audio locally on your device:
- ✅ No internet connection required
- ✅ No data sent to external servers
- ✅ Audio is processed in memory and never saved
- ✅ Only you have access to your transcriptions

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Roadmap

- [ ] Complete Whisper model integration
- [ ] Speaker diarization
- [ ] Transcription history export
- [ ] Custom vocabulary support
- [ ] Multiple language support
