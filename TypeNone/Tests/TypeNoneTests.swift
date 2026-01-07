import XCTest
@testable import TypeNone

final class TypeNoneTests: XCTestCase {
    
    // MARK: - AppState Tests
    
    func testAppStateInitialValues() {
        let appState = AppState.shared
        
        XCTAssertFalse(appState.isRecording)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertFalse(appState.showOverlay)
        XCTAssertTrue(appState.currentTranscription.isEmpty)
    }
    
    func testAppStateRecordingFlow() async {
        let appState = AppState.shared
        
        // Start recording
        await MainActor.run {
            appState.startRecording()
        }
        
        await MainActor.run {
            XCTAssertTrue(appState.isRecording)
            XCTAssertTrue(appState.showOverlay)
        }
        
        // Stop recording
        await MainActor.run {
            appState.stopRecording()
        }
        
        await MainActor.run {
            XCTAssertFalse(appState.isRecording)
            XCTAssertTrue(appState.isProcessing)
        }
        
        // Finish transcription
        await MainActor.run {
            appState.finishTranscription("Test transcription")
        }
        
        await MainActor.run {
            XCTAssertFalse(appState.isProcessing)
            XCTAssertEqual(appState.currentTranscription, "Test transcription")
            XCTAssertFalse(appState.recentTranscriptions.isEmpty)
        }
    }
    
    // MARK: - TranscriptionResult Tests
    
    func testTranscriptionResultPreview() {
        let shortText = "Hello"
        let shortResult = TranscriptionResult(text: shortText, timestamp: Date())
        XCTAssertEqual(shortResult.preview, shortText)
        
        let longText = String(repeating: "a", count: 100)
        let longResult = TranscriptionResult(text: longText, timestamp: Date())
        XCTAssertTrue(longResult.preview.count <= 53) // 50 + "..."
        XCTAssertTrue(longResult.preview.hasSuffix("..."))
    }
    
    // MARK: - WhisperModel Tests
    
    func testWhisperModelDisplayNames() {
        XCTAssertEqual(WhisperModel.tiny.displayName, "Tiny (Fastest)")
        XCTAssertEqual(WhisperModel.largeTurbo.displayName, "Large Turbo (Best)")
    }
    
    // MARK: - ClipboardService Tests
    
    func testClipboardCopy() {
        let testText = "Test clipboard content"
        ClipboardService.shared.copyToClipboard(testText)
        
        let retrieved = ClipboardService.shared.getFromClipboard()
        XCTAssertEqual(retrieved, testText)
    }
}
