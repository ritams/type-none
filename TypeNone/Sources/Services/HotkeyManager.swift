import Foundation
import HotKey
import AppKit

/// Manages global keyboard shortcuts for the application
@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    private var hotKey: HotKey?
    private var audioManager: AudioManager?
    private var transcriptionService: TranscriptionService?
    private var overlayController: OverlayWindowController?
    
    @Published var isHotkeyPressed = false
    
    private init() {}
    
    /// Register the default hotkey (⌥ + Space)
    func registerDefaultHotkey() {
        // Option + Space
        hotKey = HotKey(key: .space, modifiers: [.option])
        
        hotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.handleKeyDown()
            }
        }
        
        hotKey?.keyUpHandler = { [weak self] in
            Task { @MainActor in
                self?.handleKeyUp()
            }
        }
        
        // Pre-initialize services so model loads early
        initializeServices()
    }
    
    /// Update the hotkey combination
    func updateHotkey(key: Key, modifiers: NSEvent.ModifierFlags) {
        hotKey = nil
        hotKey = HotKey(key: key, modifiers: modifiers)
        
        hotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.handleKeyDown()
            }
        }
        
        hotKey?.keyUpHandler = { [weak self] in
            Task { @MainActor in
                self?.handleKeyUp()
            }
        }
    }
    
    /// Initialize services lazily
    func initializeServices() {
        if audioManager == nil {
            audioManager = AudioManager()
        }
        if transcriptionService == nil {
            transcriptionService = TranscriptionService()
        }
        if overlayController == nil {
            overlayController = OverlayWindowController()
        }
    }
    
    private var recordingStartTime: Date?
    private var isLockedMode = false
    
    /// Called when hotkey is pressed down
    private func handleKeyDown() {
        initializeServices()
        
        let appState = AppState.shared
        
        // If already recording
        if appState.isRecording {
            // If in locked mode, pressing the key again stops recording
            if isLockedMode {
                 stopAndTranscribe()
            }
            return
        }
        
        // Check if model is ready
        if !appState.modelLoaded {
            // Show overlay with loading message
            overlayController?.showOverlay()
            appState.currentTranscription = "Model is still loading, please wait..."
            return
        }
        
        isHotkeyPressed = true
        isLockedMode = false
        recordingStartTime = Date()
        
        // Show overlay and start recording
        overlayController?.showOverlay()
        appState.startRecording()
        
        // Start audio capture
        audioManager?.startRecording { audioLevel in
            Task { @MainActor in
                AppState.shared.audioLevel = audioLevel
            }
        }
    }
    
    /// Called when hotkey is released
    private func handleKeyUp() {
        let appState = AppState.shared
        
        // If model not loaded, just hide after a delay
        if !appState.modelLoaded {
            overlayController?.hideOverlay(afterDelay: 1.5)
            return
        }
        
        // Only process if we were recording
        guard appState.isRecording else { return }
        
        // If we are in locked mode, key up does nothing (it was the release of the toggle-on press)
        if isLockedMode {
            return
        }
        
        // Check duration to determine mode
        if let startTime = recordingStartTime, Date().timeIntervalSince(startTime) < 0.4 {
            // Short press detected -> Switch to Locked Mode
            isLockedMode = true
            return
        }
        
        // Long press detected -> Stop recording (Hold-to-record behavior)
        stopAndTranscribe()
    }
    
    /// Stop recording and process the audio
    private func stopAndTranscribe() {
        let appState = AppState.shared
        isLockedMode = false
        isHotkeyPressed = false
        recordingStartTime = nil
        
        appState.stopRecording()
        
        // Stop audio capture and get the recorded audio
        audioManager?.stopRecording { [weak self] audioData in
            Task { @MainActor in
                guard let self = self else { return }
                
                guard let audioData = audioData, !audioData.isEmpty else {
                    appState.finishTranscription("")
                    appState.currentTranscription = "No audio recorded"
                    self.overlayController?.hideOverlay(afterDelay: 1.5)
                    return
                }
                
                appState.currentTranscription = "Transcribing..."
                
                // Transcribe the audio
                do {
                    let transcription = try await self.transcriptionService?.transcribe(audioData: audioData)
                    let finalText = transcription ?? ""
                    
                    if finalText.isEmpty {
                        appState.currentTranscription = "No speech detected"
                        appState.finishTranscription("")
                    } else {
                        appState.finishTranscription(finalText)
                        
                        // Copy to clipboard if enabled
                        if appState.autoPasteEnabled {
                            ClipboardService.shared.copyToClipboard(finalText)
                            ClipboardService.shared.pasteToActiveApp()
                        }
                    }
                    
                    // Hide overlay after a delay
                    self.overlayController?.hideOverlay(afterDelay: 2.0)
                } catch {
                    print("Transcription error: \(error)")
                    appState.currentTranscription = "Transcription failed"
                    appState.finishTranscription("")
                    self.overlayController?.hideOverlay(afterDelay: 1.5)
                }
            }
        }
    }
    
    /// Cleanup resources
    func cleanup() {
        hotKey = nil
        audioManager?.cleanup()
        overlayController?.close()
    }
}
