import SwiftUI

/// Settings manager for background customization
class BackgroundSettings: ObservableObject {
    static let shared = BackgroundSettings()

    @Published var animationEnabled: Bool = true { didSet { persistIfReady() } }
    @Published var primaryWaveSpeed: Double = 0.02 { didSet { persistIfReady() } }
    @Published var secondaryWaveSpeed: Double = 0.015 { didSet { persistIfReady() } }
    @Published var primaryWaveOpacity: Double = 0.08 { didSet { persistIfReady() } }
    @Published var secondaryWaveOpacity: Double = 0.06 { didSet { persistIfReady() } }
    @Published var primaryHue: Double = 210 { didSet { persistIfReady() } }
    @Published var secondaryHue: Double = 260 { didSet { persistIfReady() } }
    @Published var waveCount: Int = 4 { didSet { persistIfReady() } }
    @Published var backgroundOpacity: Double = 0.2 { didSet { persistIfReady() } }
    @Published var glassOpacity: Double = 0.25 { didSet { persistIfReady() } }
    @Published var edgeHighlightsEnabled: Bool = true { didSet { persistIfReady() } }
    @Published var specularHighlightsEnabled: Bool = true { didSet { persistIfReady() } }
    @Published var useMetalShader: Bool = true { didSet { persistIfReady() } }  // Toggle between Canvas and Metal

    // Advanced Metal shader effects
    @Published var chromaticAberrationEnabled: Bool = false { didSet { persistIfReady() } }
    @Published var chromaticAberrationStrength: Double = 0.003 { didSet { persistIfReady() } }
    @Published var bloomEnabled: Bool = true { didSet { persistIfReady() } }
    @Published var bloomStrength: Double = 0.5 { didSet { persistIfReady() } }
    @Published var blurEnabled: Bool = false { didSet { persistIfReady() } }
    @Published var blurRadius: Double = 0.003 { didSet { persistIfReady() } }

    // Shader appearance
    @Published var shaderTransparency: Double = 85.0 { didSet { persistIfReady() } }  // 0-100%
    @Published var shaderStyle: ShaderStyle = .aurora { didSet { persistIfReady() } }  // Aurora or Ocean

    enum ShaderStyle: String, CaseIterable {
        case aurora = "Aurora"
        case ocean = "Ocean Waves"
    }

    private enum StorageKey {
        static let animationEnabled = "opal.background.animationEnabled"
        static let primaryWaveSpeed = "opal.background.primaryWaveSpeed"
        static let secondaryWaveSpeed = "opal.background.secondaryWaveSpeed"
        static let primaryWaveOpacity = "opal.background.primaryWaveOpacity"
        static let secondaryWaveOpacity = "opal.background.secondaryWaveOpacity"
        static let primaryHue = "opal.background.primaryHue"
        static let secondaryHue = "opal.background.secondaryHue"
        static let waveCount = "opal.background.waveCount"
        static let backgroundOpacity = "opal.background.backgroundOpacity"
        static let glassOpacity = "opal.background.glassOpacity"
        static let edgeHighlightsEnabled = "opal.background.edgeHighlightsEnabled"
        static let specularHighlightsEnabled = "opal.background.specularHighlightsEnabled"
        static let useMetalShader = "opal.background.useMetalShader"
        static let chromaticAberrationEnabled = "opal.background.chromaticAberrationEnabled"
        static let chromaticAberrationStrength = "opal.background.chromaticAberrationStrength"
        static let bloomEnabled = "opal.background.bloomEnabled"
        static let bloomStrength = "opal.background.bloomStrength"
        static let blurEnabled = "opal.background.blurEnabled"
        static let blurRadius = "opal.background.blurRadius"
        static let shaderTransparency = "opal.background.shaderTransparency"
        static let shaderStyle = "opal.background.shaderStyle"
    }

    private let defaults = UserDefaults.standard
    private var isHydrating = false

    private init() {
        hydrateFromDefaults()
    }

    private func hydrateFromDefaults() {
        isHydrating = true
        defer { isHydrating = false }

        animationEnabled = bool(for: StorageKey.animationEnabled, defaultValue: animationEnabled)
        primaryWaveSpeed = double(for: StorageKey.primaryWaveSpeed, defaultValue: primaryWaveSpeed)
        secondaryWaveSpeed = double(for: StorageKey.secondaryWaveSpeed, defaultValue: secondaryWaveSpeed)
        primaryWaveOpacity = double(for: StorageKey.primaryWaveOpacity, defaultValue: primaryWaveOpacity)
        secondaryWaveOpacity = double(for: StorageKey.secondaryWaveOpacity, defaultValue: secondaryWaveOpacity)
        primaryHue = double(for: StorageKey.primaryHue, defaultValue: primaryHue)
        secondaryHue = double(for: StorageKey.secondaryHue, defaultValue: secondaryHue)
        waveCount = max(1, min(8, int(for: StorageKey.waveCount, defaultValue: waveCount)))
        backgroundOpacity = double(for: StorageKey.backgroundOpacity, defaultValue: backgroundOpacity)
        glassOpacity = double(for: StorageKey.glassOpacity, defaultValue: glassOpacity)
        edgeHighlightsEnabled = bool(for: StorageKey.edgeHighlightsEnabled, defaultValue: edgeHighlightsEnabled)
        specularHighlightsEnabled = bool(for: StorageKey.specularHighlightsEnabled, defaultValue: specularHighlightsEnabled)
        useMetalShader = bool(for: StorageKey.useMetalShader, defaultValue: useMetalShader)
        chromaticAberrationEnabled = bool(for: StorageKey.chromaticAberrationEnabled, defaultValue: chromaticAberrationEnabled)
        chromaticAberrationStrength = double(for: StorageKey.chromaticAberrationStrength, defaultValue: chromaticAberrationStrength)
        bloomEnabled = bool(for: StorageKey.bloomEnabled, defaultValue: bloomEnabled)
        bloomStrength = double(for: StorageKey.bloomStrength, defaultValue: bloomStrength)
        blurEnabled = bool(for: StorageKey.blurEnabled, defaultValue: blurEnabled)
        blurRadius = double(for: StorageKey.blurRadius, defaultValue: blurRadius)
        shaderTransparency = max(0, min(100, double(for: StorageKey.shaderTransparency, defaultValue: shaderTransparency)))

        let style = defaults.string(forKey: StorageKey.shaderStyle) ?? shaderStyle.rawValue
        shaderStyle = ShaderStyle(rawValue: style) ?? .aurora
    }

    private func persistIfReady() {
        guard !isHydrating else { return }

        defaults.set(animationEnabled, forKey: StorageKey.animationEnabled)
        defaults.set(primaryWaveSpeed, forKey: StorageKey.primaryWaveSpeed)
        defaults.set(secondaryWaveSpeed, forKey: StorageKey.secondaryWaveSpeed)
        defaults.set(primaryWaveOpacity, forKey: StorageKey.primaryWaveOpacity)
        defaults.set(secondaryWaveOpacity, forKey: StorageKey.secondaryWaveOpacity)
        defaults.set(primaryHue, forKey: StorageKey.primaryHue)
        defaults.set(secondaryHue, forKey: StorageKey.secondaryHue)
        defaults.set(waveCount, forKey: StorageKey.waveCount)
        defaults.set(backgroundOpacity, forKey: StorageKey.backgroundOpacity)
        defaults.set(glassOpacity, forKey: StorageKey.glassOpacity)
        defaults.set(edgeHighlightsEnabled, forKey: StorageKey.edgeHighlightsEnabled)
        defaults.set(specularHighlightsEnabled, forKey: StorageKey.specularHighlightsEnabled)
        defaults.set(useMetalShader, forKey: StorageKey.useMetalShader)
        defaults.set(chromaticAberrationEnabled, forKey: StorageKey.chromaticAberrationEnabled)
        defaults.set(chromaticAberrationStrength, forKey: StorageKey.chromaticAberrationStrength)
        defaults.set(bloomEnabled, forKey: StorageKey.bloomEnabled)
        defaults.set(bloomStrength, forKey: StorageKey.bloomStrength)
        defaults.set(blurEnabled, forKey: StorageKey.blurEnabled)
        defaults.set(blurRadius, forKey: StorageKey.blurRadius)
        defaults.set(shaderTransparency, forKey: StorageKey.shaderTransparency)
        defaults.set(shaderStyle.rawValue, forKey: StorageKey.shaderStyle)
    }

    private func bool(for key: String, defaultValue: Bool) -> Bool {
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    private func double(for key: String, defaultValue: Double) -> Double {
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.double(forKey: key)
    }

    private func int(for key: String, defaultValue: Int) -> Int {
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.integer(forKey: key)
    }
}

/// Liquid Glass background effect using Metal shaders
struct LiquidGlassBackground: View {
    @StateObject private var settings = BackgroundSettings.shared
    
    var body: some View {
        ZStack {
            if settings.useMetalShader {
                // Use Metal-based shader for GPU acceleration
                MetalLiquidGlassBackground(settings: settings)
            } else {
                // Fallback to Canvas-based rendering
                CanvasLiquidGlassBackground()
            }
        }
    }
}

// MARK: - Canvas-based Fallback (Original Implementation)

struct CanvasLiquidGlassBackground: View {
    @StateObject private var settings = BackgroundSettings.shared
    @State private var phase = 0.0
    @State private var secondaryPhase = 0.0
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background - allows window transparency to show through
                Color.clear
                
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
