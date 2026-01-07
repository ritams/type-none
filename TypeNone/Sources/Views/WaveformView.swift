import SwiftUI

/// Audio waveform visualization view
struct WaveformView: View {
    let level: Float
    var barCount: Int = 12
    
    @State private var animatedLevels: [Float] = []
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) { // Increased spacing
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        height: barHeight(for: index, in: geometry.size.height),
                        maxHeight: geometry.size.height
                    )
                }
            }
            // Center the bars horizontally
            .frame(width: geometry.size.width, alignment: .center)
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
            .fill(Color.white) // Pure white for high contrast on dark background
            .frame(width: 4, height: height)
            .frame(height: maxHeight, alignment: .center)
            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0) // Glow effect
    }
}
