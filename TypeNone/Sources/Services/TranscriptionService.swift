import Foundation
import SwiftWhisper
import CryptoKit
import Combine

/// Service for transcribing audio using Whisper
@MainActor
class TranscriptionService: NSObject, WhisperDelegate {
    private var whisper: Whisper?
    private var isModelLoaded = false
    private var modelLoadingTask: Task<Void, Error>?
    
    // Callback for progress updates during transcription
    var onProgressUpdate: ((Double) -> Void)?
    var onNewSegments: (([Segment]) -> Void)?
    
    // Model file paths
    private var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let typeNoneDir = appSupport.appendingPathComponent("TypeNone", isDirectory: true)
        return typeNoneDir.appendingPathComponent("Models", isDirectory: true)
    }
    
    private var modelPath: URL {
        modelDirectory.appendingPathComponent(AppState.shared.modelName)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        // Start loading the model in background
        loadModelAsync()
        
        // Observe model changes

        
        // Just verify/load once on startup
    }
    
    /// Check if model file exists
    func isModelDownloaded() -> Bool {
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    /// Get model file size in MB
    func getModelSize() -> Double? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: modelPath.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return Double(size) / 1_000_000
    }
    
    /// Download the Whisper model
    func downloadModel() async throws {
        // Simplified: Use fixed Medium model
        let modelName = AppState.shared.modelName
        let modelURL = AppState.shared.modelUrl
        
        // Create model directory if needed
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        
        print("Downloading \(modelName)...")
        
        let downloader = ModelDownloader()
        
        // Download with progress
        let tempURL = try await downloader.download(from: modelURL) { progress in
            Task { @MainActor in
                // Download phase is 0% -> 50%
                AppState.shared.modelLoadingProgress = progress * 0.5
            }
        }
        
        // Skip integrity check as requested by user to simplify
        
        // Move to final location
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.removeItem(at: modelPath)
        }
        try FileManager.default.moveItem(at: tempURL, to: modelPath)
        
        print("Model downloaded to: \(modelPath.path)")
    }
    
    // Internal helper for downloading with progress
    private class ModelDownloader: NSObject, URLSessionDownloadDelegate {
        private var continuation: CheckedContinuation<URL, Error>?
        private var progressHandler: ((Double) -> Void)?
        
        func download(from url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
            self.progressHandler = progress
            
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                let task = session.downloadTask(with: url)
                task.resume()
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            // Move to a temporary location that persists after function return
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(UUID().uuidString)
            
            do {
                try FileManager.default.moveItem(at: location, to: tempFile)
                continuation?.resume(returning: tempFile)
            } catch {
                continuation?.resume(throwing: error)
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler?(progress)
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                continuation?.resume(throwing: error)
            }
        }
    }
    
    /// Load the Whisper model asynchronously
    private func loadModelAsync() {
        modelLoadingTask = Task {
            do {
                // Check if model exists, if not download it
                if !isModelDownloaded() {
                    await MainActor.run {
                        AppState.shared.modelLoaded = false
                        AppState.shared.modelLoadingProgress = 0.01
                    }
                    print("Downloading Whisper model...")
                    try await downloadModel()
                }
                
                await MainActor.run {
                    AppState.shared.modelLoadingProgress = 0.5
                }
                
                // Load the model
                try await loadModel()
                
                await MainActor.run {
                    AppState.shared.modelLoaded = true
                    AppState.shared.modelLoadingProgress = 1.0
                }
            } catch {
                print("Failed to load model: \(error)")
            }
        }
    }
    
    /// Load the Whisper model
    private func loadModel() async throws {
        guard isModelDownloaded() else {
            throw TranscriptionError.modelNotLoaded
        }
        
        print("Loading Whisper model from: \(modelPath.path)")
        
        whisper = Whisper(fromFileURL: modelPath)
        whisper?.delegate = self
        
        isModelLoaded = true
        print("Whisper model loaded successfully")
    }
    
    /// Transcribe audio data to text
    func transcribe(audioData: Data) async throws -> String {
        // Wait for model to be loaded
        if let task = modelLoadingTask {
            try await task.value
        }
        
        guard isModelLoaded, let whisper = whisper else {
            throw TranscriptionError.modelNotLoaded
        }
        
        // Convert Data to [Float]
        let audioFrames = convertDataToFrames(audioData)
        
        guard !audioFrames.isEmpty else {
            return ""
        }
        
        print("Transcribing \(audioFrames.count) audio frames...")
        
        // Transcribe
        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        
        // Join all segments into final text
        let text = segments.map { $0.text }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Transcription complete: \(text)")
        
        return text
    }
    
    /// Convert Data (float32 samples) to [Float]
    private func convertDataToFrames(_ data: Data) -> [Float] {
        let floatCount = data.count / MemoryLayout<Float>.size
        var floats = [Float](repeating: 0, count: floatCount)
        
        _ = floats.withUnsafeMutableBytes { floatsPtr in
            data.copyBytes(to: floatsPtr)
        }
        
        return floats
    }
    
    // MARK: - WhisperDelegate
    
    nonisolated func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        Task { @MainActor in
            AppState.shared.modelLoadingProgress = 0.5 + (progress * 0.5)
            self.onProgressUpdate?(progress)
        }
    }
    
    nonisolated func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        Task { @MainActor in
            // Update current transcription with partial results
            let partialText = segments.map { $0.text }.joined()
            AppState.shared.currentTranscription = partialText.trimmingCharacters(in: .whitespacesAndNewlines)
            self.onNewSegments?(segments)
        }
    }
    
    nonisolated func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
        // Final transcription handled in transcribe() return
    }
    
    nonisolated func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
        print("Whisper error: \(error)")
    }
}

/// Errors that can occur during transcription
enum TranscriptionError: Error, LocalizedError {
    case modelNotLoaded
    case modelDownloadFailed(String)
    case invalidAudioFormat
    case transcriptionFailed(String)
    case integrityCheckFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Whisper model is not loaded yet"
        case .modelDownloadFailed(let reason):
            return "Failed to download model: \(reason)"
        case .invalidAudioFormat:
            return "Invalid audio format provided"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .integrityCheckFailed:
            return "Model file integrity check failed."
        }
    }
}
