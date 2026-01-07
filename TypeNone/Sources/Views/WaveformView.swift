import SwiftUI

/// Audio waveform visualization view
struct WaveformView: View {
    let level: Float
    let barCount: Int = 12
    
    @State private var animatedLevels: [Float] = []
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        height: barHeight(for: index, in: geometry.size.height),
                        maxHeight: geometry.size.height
                    )
                }
            }
        }
        .onChange(of: level) { _, newLevel in
            updateLevels(newLevel)
        }
        .onAppear {
            animatedLevels = Array(repeating: 0, count: barCount)
        }
    }
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        guard index < animatedLevels.count else { return 4 }
        
        let level = animatedLevels[index]
        let minHeight: CGFloat = 4
        let height = minHeight + CGFloat(level) * (maxHeight - minHeight)
        
        return height
    }
    
    private func updateLevels(_ newLevel: Float) {
        // Shift existing levels to the left
        var newLevels = animatedLevels
        if newLevels.count > 1 {
            newLevels.removeFirst()
            newLevels.append(newLevel)
        } else {
            newLevels = [newLevel]
        }
        
        withAnimation(.easeOut(duration: 0.1)) {
            animatedLevels = newLevels
        }
    }
}

/// Individual bar in the waveform
struct WaveformBar: View {
    let height: CGFloat
    let maxHeight: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barGradient)
            .frame(width: 4, height: height)
            .frame(height: maxHeight, alignment: .center)
    }
    
    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

/// Alternative: Circular waveform visualization
struct CircularWaveformView: View {
    let level: Float
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.blue.opacity(0.3), .cyan.opacity(0.6), .blue.opacity(0.3)],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .scaleEffect(1 + CGFloat(level) * 0.2)
            
            // Inner pulsing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue.opacity(0.6), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .scaleEffect(1 + CGFloat(level) * 0.5)
            
            // Microphone icon
            Image(systemName: "mic.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
