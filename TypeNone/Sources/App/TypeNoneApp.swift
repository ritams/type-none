import SwiftUI

/// Main entry point for Type None - a menu bar app for real-time transcription
@main
struct TypeNoneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        // Menu bar presence
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(appState.isRecording ? .red : .primary)
        }
        .menuBarExtraStyle(.window)
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

/// App delegate for handling app lifecycle and global hotkey registration
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize hotkey manager
        Task { @MainActor in
            hotkeyManager = HotkeyManager.shared
            
            // Register default hotkey if not set
            hotkeyManager?.registerDefaultHotkey()
        }
        
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        Task { @MainActor in
            hotkeyManager?.cleanup()
        }
    }
}
