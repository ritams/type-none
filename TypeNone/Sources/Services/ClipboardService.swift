import AppKit
import Carbon.HIToolbox

/// Service for clipboard operations and pasting to active app
class ClipboardService {
    static let shared = ClipboardService()
    
    private let pasteboard = NSPasteboard.general
    
    private init() {}
    
    /// Copy text to the system clipboard
    func copyToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Get text from the clipboard
    func getFromClipboard() -> String? {
        return pasteboard.string(forType: .string)
    }
    
    /// Simulate paste action (Cmd+V) in the active application
    func pasteToActiveApp() {
        // 1. Hide our app explicitly to return focus to previous app
        DispatchQueue.main.async {
            NSApp.hide(nil)
        }
        
        // 2. Wait a bit for focus to settle, then paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.simulatePaste()
        }
    }
    
    /// Simulate Cmd+V keystroke using AppleScript (More robust)
    private func simulatePaste() {
        let scriptSource = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript paste error: \(error)")
                // Fallback to CGEvent if AppleScript fails
                simulatePasteCGEvent()
            }
        } else {
            simulatePasteCGEvent()
        }
    }
    
    /// Fallback: Simulate Cmd+V using CGEvent
    private func simulatePasteCGEvent() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode = CGKeyCode(9) // kVK_ANSI_V
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Check if we have accessibility permissions (required for paste simulation)
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Type text directly using keyboard events (alternative to paste)
    func typeText(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        for character in text {
            let utf16 = Array(String(character).utf16)
            
            // Create keyboard event with Unicode
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
                event.post(tap: .cghidEventTap)
            }
            
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                event.post(tap: .cghidEventTap)
            }
            
            // Small delay between characters
            usleep(1000) // 1ms
        }
    }
}
