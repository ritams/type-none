import SwiftUI
import AppKit

/// Controller for the floating overlay window
@MainActor
class OverlayWindowController {
    private var window: NSWindow?
    private var hostingController: NSHostingController<OverlayContentView>?
    
    init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let contentView = OverlayContentView()
        hostingController = NSHostingController(rootView: contentView)
        
        // Create borderless, floating window
        // Wider frame for the waveform
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        // Configure window properties
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = false // Remove shadow for isolated look
        
        // Position at bottom center of screen
        positionWindow()
    }
    
    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 150 // Slightly higher up
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func showOverlay() {
        guard let window = window else { return }
        
        positionWindow()
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }
    }
    
    func hideOverlay(afterDelay delay: TimeInterval = 0) {
        guard let window = window else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Fade out
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 0
            } completionHandler: {
                Task { @MainActor in
                    window.orderOut(nil)
                    AppState.shared.hideOverlay()
                }
            }
        }
    }
    
    func close() {
        window?.close()
        window = nil
    }
}

/// The content view for the floating overlay
struct OverlayContentView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        HStack(spacing: 0) {
            if appState.isRecording {
                // Isolated Minimal Waveform
                WaveformView(level: appState.audioLevel, barCount: 30)
                    .frame(height: 50)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7)) // Minimal dark background for contrast
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else if !appState.modelLoaded {
                 // Minimal loading pill
                 HStack(spacing: 8) {
                     ProgressView()
                         .controlSize(.small)
                         .colorScheme(.dark)
                     Text("Loading...")
                         .font(.caption)
                         .foregroundStyle(.white.opacity(0.8))
                 }
                 .padding(.horizontal, 16)
                 .padding(.vertical, 8)
                 .background(Color.black.opacity(0.7))
                 .clipShape(Capsule())
            }
        }
        .frame(width: 600, height: 100)
    }
}
