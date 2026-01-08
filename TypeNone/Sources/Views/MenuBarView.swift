import SwiftUI

/// The menu bar dropdown view
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) var openWindow
    @State private var isHoveringQuit = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Status Section
            statusSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Recent Transcriptions
            recentTranscriptionsSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Actions
            actionsSection
        }
        .padding()
        .frame(width: 320)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Type None")
                    .font(.headline)
                Text("Real-time Transcription")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Model status indicator
            if appState.modelLoaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help("Model loaded")
            } else {
                ProgressView()
                    .scaleEffect(0.7)
                    .help("Loading model...")
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.subheadline)
                Spacer()
            }
            
            // Hotkey hint
            HStack {
                Text("Hotkey:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("⌥ Space")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                Text("(hold to record)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var statusColor: Color {
        if appState.isRecording {
            return .red
        } else if appState.isProcessing {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if appState.isRecording {
            return "Recording..."
        } else if appState.isProcessing {
            return "Processing..."
        } else {
            return "Ready"
        }
    }
    
    // MARK: - Recent Transcriptions
    
    private var recentTranscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                if !appState.recentTranscriptions.isEmpty {
                    Button("Clear") {
                        appState.recentTranscriptions.removeAll()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            
            if appState.recentTranscriptions.isEmpty {
                Text("No recent transcriptions")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(appState.recentTranscriptions.prefix(5)) { transcription in
                    TranscriptionRow(transcription: transcription)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 8) {
            Button {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Microphone Settings", systemImage: "mic")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if #available(macOS 14.0, *) {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                } label: {
                    Label("Preferences...", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .keyboardShortcut(",", modifiers: .command)
            } else {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                } label: {
                    Label("Preferences...", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .keyboardShortcut(",", modifiers: .command)
            }
            
            Divider()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Type None", systemImage: "power")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

// MARK: - Transcription Row

struct TranscriptionRow: View {
    let transcription: TranscriptionResult
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transcription.preview)
                    .font(.caption)
                    .lineLimit(1)
                Text(transcription.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if isHovering {
                Button {
                    ClipboardService.shared.copyToClipboard(transcription.text)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
