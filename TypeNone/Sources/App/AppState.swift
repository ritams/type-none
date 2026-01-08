import SwiftUI
import Combine

/// Global application state shared across all views
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Recording State
    @Published var isRecording: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showOverlay: Bool = false
    
    // MARK: - Transcription State
    @Published var currentTranscription: String = ""
    @Published var recentTranscriptions: [TranscriptionResult] = []
    
    // MARK: - Audio State
    @Published var audioLevel: Float = 0.0
    @Published var selectedInputDevice: String = "Default"
    
    // MARK: - Model State
    @Published var modelLoaded: Bool = false
    @Published var modelLoadingProgress: Double = 0.0
    
    // Simplified: Always use Medium model
    let modelName = "ggml-medium.bin"
    let modelUrl = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin")!
    
    // MARK: - Settings
    @AppStorage("autoPasteEnabled") var autoPasteEnabled: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("showWaveform") var showWaveform: Bool = true
    
    private init() {}
    
    // MARK: - Actions
    
    func startRecording() {
        isRecording = true
        showOverlay = true
        currentTranscription = ""
    }
    
    func stopRecording() {
        isRecording = false
        isProcessing = true
    }
    
    func finishTranscription(_ text: String) {
        isProcessing = false
        currentTranscription = text
        
        // Add to history
        let result = TranscriptionResult(text: text, timestamp: Date())
        recentTranscriptions.insert(result, at: 0)
        
        // Keep only last 10
        if recentTranscriptions.count > 10 {
            recentTranscriptions.removeLast()
        }
    }
    
    func hideOverlay() {
        showOverlay = false
        currentTranscription = ""
    }
}

// MARK: - Supporting Types

struct TranscriptionResult: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var preview: String {
        if text.count <= 50 {
            return text
        }
        return String(text.prefix(50)) + "..."
    }
}


