import SwiftUI
import ServiceManagement
import HotKey
import AppKit

/// Settings/Preferences view
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            TranscriptionSettingsView()
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 320)
    }
}

/// General settings tab
struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var launchAtLogin = false
    @State private var selectedModifier: ModifierOption = .option
    @State private var selectedKey: KeyOption = .space
    
    var body: some View {
        Form {
            Section {
                // Keyboard shortcut configuration
                HStack {
                    Text("Activation Shortcut")
                    Spacer()
                    
                    Picker("Modifier", selection: $selectedModifier) {
                        ForEach(ModifierOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .frame(width: 100)
                    
                    Text("+")
                    
                    Picker("Key", selection: $selectedKey) {
                        ForEach(KeyOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .frame(width: 80)
                }
                .onChange(of: selectedModifier) { _, _ in
                    updateHotkey()
                }
                .onChange(of: selectedKey) { _, _ in
                    updateHotkey()
                }
                
                Text("Press and hold this shortcut to record, release to transcribe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Toggle("Auto-paste transcription", isOn: $appState.autoPasteEnabled)
                
                Text("Automatically paste the transcription to the active text field")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Toggle("Show waveform during recording", isOn: $appState.showWaveform)
            }
            
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            launchAtLogin = getLaunchAtLoginStatus()
        }
    }
    
    private func updateHotkey() {
        Task { @MainActor in
            HotkeyManager.shared.updateHotkey(
                key: selectedKey.hotKeyKey,
                modifiers: selectedModifier.modifierFlags
            )
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
    
    private func getLaunchAtLoginStatus() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
}

// MARK: - Hotkey Option Types

enum ModifierOption: String, CaseIterable, Identifiable {
    case option = "option"
    case command = "command"
    case control = "control"
    case optionCommand = "option+command"
    case controlOption = "control+option"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .option: return "⌥ Option"
        case .command: return "⌘ Command"
        case .control: return "⌃ Control"
        case .optionCommand: return "⌥⌘"
        case .controlOption: return "⌃⌥"
        }
    }
    
    var modifierFlags: NSEvent.ModifierFlags {
        switch self {
        case .option: return [.option]
        case .command: return [.command]
        case .control: return [.control]
        case .optionCommand: return [.option, .command]
        case .controlOption: return [.control, .option]
        }
    }
}

enum KeyOption: String, CaseIterable, Identifiable {
    case space = "space"
    case t = "t"
    case d = "d"
    case r = "r"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .space: return "Space"
        case .t: return "T"
        case .d: return "D"
        case .r: return "R"
        }
    }
    
    var hotKeyKey: Key {
        switch self {
        case .space: return .space
        case .t: return .t
        case .d: return .d
        case .r: return .r
        }
    }
}

/// Transcription settings tab
struct TranscriptionSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var audioDevices: [String] = ["Default"]
    
    var body: some View {
        Form {
            Section {
                Picker("Model", selection: $appState.selectedModel) {
                    ForEach(WhisperModel.allCases) { model in
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                            Text(model.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model)
                    }
                }
                
                if !appState.modelLoaded {
                    HStack {
                        Text("Loading model...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: appState.modelLoadingProgress)
                            .progressViewStyle(.linear)
                    }
                }
            } header: {
                Text("Model")
            }
            
            Section {
                Picker("Input Device", selection: $appState.selectedInputDevice) {
                    ForEach(audioDevices, id: \.self) { device in
                        Text(device)
                    }
                }
                
                Button("Refresh Devices") {
                    refreshAudioDevices()
                }
                .buttonStyle(.link)
            } header: {
                Text("Audio")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            refreshAudioDevices()
        }
    }
    
    private func refreshAudioDevices() {
        let audioManager = AudioManager()
        audioDevices = audioManager.getAvailableInputDevices()
    }
}

/// About tab
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("Type None")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Real-time audio to text transcription,\naccessible anywhere through a keyboard shortcut.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("Powered by Whisper")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Running locally on your Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Link("View on GitHub", destination: URL(string: "https://github.com/ritam/type-none")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
