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
        // Small delay to ensure clipboard is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    /// Simulate Cmd+V keystroke
    private func simulatePaste() {
        // Create key down event for Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        // V key code is 9
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        
        // Post the events
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
