import SwiftUI

/// Settings manager for background customization
class BackgroundSettings: ObservableObject {
    static let shared = BackgroundSettings()
    
    @Published var animationEnabled: Bool = true
    @Published var primaryWaveSpeed: Double = 0.02
    @Published var secondaryWaveSpeed: Double = 0.015
    @Published var primaryWaveOpacity: Double = 0.08
    @Published var secondaryWaveOpacity: Double = 0.06
    @Published var primaryHue: Double = 210
    @Published var secondaryHue: Double = 260
    @Published var waveCount: Int = 4
    @Published var backgroundOpacity: Double = 0.2
    @Published var glassOpacity: Double = 0.25
    @Published var edgeHighlightsEnabled: Bool = true
    @Published var specularHighlightsEnabled: Bool = true
    
    private init() {}
}

/// Liquid Glass background effect for macOS 15+
/// Creates a stunning glass morphism effect with animated aurora waves
struct LiquidGlassBackground: View {
    @StateObject private var settings = BackgroundSettings.shared
    @State private var phase = 0.0
    @State private var secondaryPhase = 0.0
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep space background
                Color.black.opacity(settings.backgroundOpacity)
                
                // Primary aurora layer - slow flowing waves
                AuroraWaveLayer(
                    phase: phase,
                    colorHue: settings.primaryHue,
                    waveCount: settings.waveCount,
                    opacity: settings.primaryWaveOpacity,
                    speed: 1.0
                )
                
                // Secondary aurora layer - faster counter-rotation
                AuroraWaveLayer(
                    phase: secondaryPhase,
                    colorHue: settings.secondaryHue,
                    waveCount: max(1, settings.waveCount - 1),
                    opacity: settings.secondaryWaveOpacity,
                    speed: -0.7
                )
                
                // Material glass layer
                GlassMaterialLayer(opacity: settings.glassOpacity)
                
                // Edge highlights
                if settings.edgeHighlightsEnabled {
                    EdgeHighlights()
                }
                
                // Specular highlights
                if settings.specularHighlightsEnabled {
                    SpecularHighlights()
                }
            }
            .onReceive(timer) { _ in
                if settings.animationEnabled {
                    phase += settings.primaryWaveSpeed
                    secondaryPhase += settings.secondaryWaveSpeed
                }
            }
        }
    }
}

// MARK: - Aurora Wave Layer

struct AuroraWaveLayer: View {
    let phase: Double
    let colorHue: Double
    let waveCount: Int
    let opacity: Double
    let speed: Double
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            
            for i in 0..<waveCount {
                let offset = Double(i) * 1.5
                var path = Path()
                
                let baseY = height * 0.15 + CGFloat(i) * height * 0.18
                
                path.move(to: CGPoint(x: 0, y: baseY))
                
                for x in stride(from: 0, through: width, by: 2) {
                    let normalizedX = Double(x) / Double(width) * Double.pi * 4
                    let wave1 = sin(normalizedX + phase * speed + offset) * 50
                    let wave2 = sin(normalizedX * 1.7 + phase * speed * 0.6 + offset) * 30
                    let wave3 = sin(normalizedX * 0.3 + phase * speed * 1.2) * 20
                    let y = baseY + CGFloat(wave1 + wave2 + wave3)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
                
                let hue = colorHue + Double(i) * 20.0
                let color = Color(
                    hue: hue / 360.0,
                    saturation: 0.8,
                    brightness: 0.9,
                    opacity: max(opacity - Double(i) * 0.015, 0.02)
                )
                
                context.fill(path, with: .color(color))
            }
        }
    }
}

// MARK: - Glass Material Layer

struct GlassMaterialLayer: View {
    let opacity: Double
    
    var body: some View {
        ZStack {
            // Primary glass material
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)
            
            // Secondary thin material for depth
            Rectangle()
                .fill(.thinMaterial)
                .opacity(0.1)
        }
    }
}

// MARK: - Edge Highlights

struct EdgeHighlights: View {
    var body: some View {
        ZStack {
            // Top highlight
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1.5)
                
                Spacer()
            }
            
            // Side highlights
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 1.5)
                
                Spacer()
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 1)
            }
        }
    }
}

// MARK: - Specular Highlights

struct SpecularHighlights: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top specular
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background to show transparency
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        LiquidGlassBackground()
    }
    .frame(width: 800, height: 600)
}
