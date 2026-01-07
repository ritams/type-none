import SwiftUI

/// Main entry point for Type None - a menu bar app for real-time transcription
@main
struct TypeNoneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @State private var showingPermissionAlert = false
    
    init() {
        // Permission check handled in onAppear
    }
    
    var body: some Scene {
        // Menu bar presence
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .onAppear {
                    checkPermissions()
                }
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
                .alert("Permission Required", isPresented: $showingPermissionAlert) {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Type None needs Accessibility permissions to paste text into other applications. Please grant access in System Settings.")
                }
        }
    }
    
    private func checkPermissions() {
        if !ClipboardService.shared.checkAccessibilityPermission() {
            // Slight delay and check again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !ClipboardService.shared.checkAccessibilityPermission() {
                     showingPermissionAlert = true
                }
            }
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
