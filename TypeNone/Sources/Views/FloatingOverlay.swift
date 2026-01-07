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
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
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
        window.hasShadow = true
        
        // Position at bottom center of screen
        positionWindow()
    }
    
    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 100 // 100 points from bottom
        
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
                context.duration = 0.3
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
        VStack(spacing: 12) {
            // Model loading status
            if !appState.modelLoaded {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.modelLoadingProgress < 0.1 ? "Downloading Whisper model..." : "Loading Whisper model...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: appState.modelLoadingProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 150)
                    }
                    Spacer()
                }
            }
            // Recording indicator and waveform
            else if appState.isRecording {
                HStack(spacing: 8) {
                    // Pulsing record indicator
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .modifier(PulseModifier())
                    
                    Text("Recording...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Audio level indicator
                    if appState.showWaveform {
                        WaveformView(level: appState.audioLevel)
                            .frame(width: 100, height: 24)
                    }
                }
            } else if appState.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Transcribing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            // Transcription text
            if !appState.currentTranscription.isEmpty {
                Text(appState.currentTranscription)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(4)
            } else if appState.modelLoaded && !appState.isRecording && !appState.isProcessing {
                Text("Press and hold ⌥ Space to record")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(width: 400)
        .frame(minHeight: 80)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
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
