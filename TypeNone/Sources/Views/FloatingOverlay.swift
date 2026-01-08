import SwiftUI
import AppKit

/// Custom window that doesn't steal focus
class FloatingPanel: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Controller for the floating overlay window
@MainActor
class OverlayWindowController {
    private var window: FloatingPanel?
    private var hostingController: NSHostingController<OverlayContentView>?
    
    init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let contentView = OverlayContentView()
        hostingController = NSHostingController(rootView: contentView)
        
        // Create borderless, floating window
        window = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 60), // Smaller size
            styleMask: [.borderless, .nonactivatingPanel], // Non-activating
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        // Configure window properties
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        window.isMovableByWindowBackground = true
        window.hasShadow = false
        window.ignoresMouseEvents = true // Pass interactions through
        
        // Position at bottom center of screen
        positionWindow()
    }
    
    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 120
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func showOverlay() {
        guard let window = window else { return }
        
        positionWindow()
        window.alphaValue = 0
        window.orderFront(nil) // Don't make key!
        
        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        }
    }
    
    func hideOverlay(afterDelay delay: TimeInterval = 0) {
        guard let window = window else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Fade out
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
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
                // Extremely Minimal Waveform
                WaveformView(level: appState.audioLevel, barCount: 20)
                    .frame(height: 32) // Smaller height
            } else if !appState.modelLoaded {
                 // Minimal loading dot
                 Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .modifier(PulseModifier())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // No background at all, just content
        .frame(width: 300, height: 60)
        .frame(width: 300, height: 60)
        .overlay(alignment: .trailing) {
            Button {
                // Toggle lock/unlock
                if appState.isRecording {
                    HotkeyManager.shared.stopRecording()
                } else {
                    HotkeyManager.shared.startRecording()
                }
            } label: {
                Image(systemName: appState.isRecording ? "lock.fill" : "lock.open")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .help(appState.isRecording ? "Stop Recording" : "Start Recording (Lock)")
        }
        .overlay(alignment: .bottom) {
             if !appState.isRecording && appState.modelLoaded {
                 Text("Tap to lock · Hold to record")
                     .font(.system(size: 10))
                     .foregroundStyle(.white.opacity(0.5))
                     .padding(.bottom, 4)
             }
        }
    }
}

/// Pulsing animation modifier for recording indicator
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Visual effect blur for the overlay background
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
