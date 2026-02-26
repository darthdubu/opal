import Foundation
import SwiftUI

final class BackgroundProfile: ObservableObject {
    static let shared = BackgroundProfile()

    @Published var useMetalShader: Bool = true { didSet { persistIfReady() } }
    @Published var animationEnabled: Bool = true { didSet { persistIfReady() } }

    @Published var primaryWaveSpeed: Double = 0.02 { didSet { persistIfReady() } }
    @Published var secondaryWaveSpeed: Double = 0.015 { didSet { persistIfReady() } }
    @Published var primaryWaveOpacity: Double = 0.08 { didSet { persistIfReady() } }
    @Published var secondaryWaveOpacity: Double = 0.06 { didSet { persistIfReady() } }

    @Published var primaryHue: Double = 210 { didSet { persistIfReady() } }
    @Published var secondaryHue: Double = 260 { didSet { persistIfReady() } }
    @Published var waveCount: Int = 4 { didSet { persistIfReady() } }

    @Published var bloomEnabled: Bool = true { didSet { persistIfReady() } }
    @Published var bloomStrength: Double = 0.5 { didSet { persistIfReady() } }
    @Published var chromaticAberrationEnabled: Bool = false { didSet { persistIfReady() } }
    @Published var chromaticAberrationStrength: Double = 0.003 { didSet { persistIfReady() } }
    @Published var blurEnabled: Bool = false { didSet { persistIfReady() } }
    @Published var blurRadius: Double = 0.003 { didSet { persistIfReady() } }

    // 0-100 where 100 means fully transparent shader layer.
    @Published var shaderTransparency: Double = 85.0 { didSet { persistIfReady() } }
    @Published var shaderStyle: ShaderStyle = .aurora { didSet { persistIfReady() } }

    enum ShaderStyle: String, CaseIterable {
        case aurora = "Aurora"
        case ocean = "Ocean Waves"
    }

    private enum StorageKey {
        static let useMetalShader = "opal.background.useMetalShader"
        static let animationEnabled = "opal.background.animationEnabled"
        static let primaryWaveSpeed = "opal.background.primaryWaveSpeed"
        static let secondaryWaveSpeed = "opal.background.secondaryWaveSpeed"
        static let primaryWaveOpacity = "opal.background.primaryWaveOpacity"
        static let secondaryWaveOpacity = "opal.background.secondaryWaveOpacity"
        static let primaryHue = "opal.background.primaryHue"
        static let secondaryHue = "opal.background.secondaryHue"
        static let waveCount = "opal.background.waveCount"
        static let bloomEnabled = "opal.background.bloomEnabled"
        static let bloomStrength = "opal.background.bloomStrength"
        static let chromaticAberrationEnabled = "opal.background.chromaticAberrationEnabled"
        static let chromaticAberrationStrength = "opal.background.chromaticAberrationStrength"
        static let blurEnabled = "opal.background.blurEnabled"
        static let blurRadius = "opal.background.blurRadius"
        static let shaderTransparency = "opal.background.shaderTransparency"
        static let shaderStyle = "opal.background.shaderStyle"
    }

    private let defaults = UserDefaults.standard
    private var hydrating = false

    private init() {
        hydrateFromDefaults()
    }

    private func hydrateFromDefaults() {
        hydrating = true
        defer { hydrating = false }

        useMetalShader = bool(for: StorageKey.useMetalShader, defaultValue: useMetalShader)
        animationEnabled = bool(for: StorageKey.animationEnabled, defaultValue: animationEnabled)

        primaryWaveSpeed = double(for: StorageKey.primaryWaveSpeed, defaultValue: primaryWaveSpeed)
        secondaryWaveSpeed = double(for: StorageKey.secondaryWaveSpeed, defaultValue: secondaryWaveSpeed)
        primaryWaveOpacity = double(for: StorageKey.primaryWaveOpacity, defaultValue: primaryWaveOpacity)
        secondaryWaveOpacity = double(for: StorageKey.secondaryWaveOpacity, defaultValue: secondaryWaveOpacity)

        primaryHue = clamp(double(for: StorageKey.primaryHue, defaultValue: primaryHue), lower: 0, upper: 360)
        secondaryHue = clamp(double(for: StorageKey.secondaryHue, defaultValue: secondaryHue), lower: 0, upper: 360)
        waveCount = max(1, min(8, int(for: StorageKey.waveCount, defaultValue: waveCount)))

        bloomEnabled = bool(for: StorageKey.bloomEnabled, defaultValue: bloomEnabled)
        bloomStrength = double(for: StorageKey.bloomStrength, defaultValue: bloomStrength)
        chromaticAberrationEnabled = bool(for: StorageKey.chromaticAberrationEnabled, defaultValue: chromaticAberrationEnabled)
        chromaticAberrationStrength = double(for: StorageKey.chromaticAberrationStrength, defaultValue: chromaticAberrationStrength)
        blurEnabled = bool(for: StorageKey.blurEnabled, defaultValue: blurEnabled)
        blurRadius = double(for: StorageKey.blurRadius, defaultValue: blurRadius)

        shaderTransparency = clamp(double(for: StorageKey.shaderTransparency, defaultValue: shaderTransparency), lower: 0, upper: 100)
        shaderStyle = ShaderStyle(rawValue: defaults.string(forKey: StorageKey.shaderStyle) ?? "") ?? .aurora
    }

    private func persistIfReady() {
        guard !hydrating else { return }

        defaults.set(useMetalShader, forKey: StorageKey.useMetalShader)
        defaults.set(animationEnabled, forKey: StorageKey.animationEnabled)

        defaults.set(primaryWaveSpeed, forKey: StorageKey.primaryWaveSpeed)
        defaults.set(secondaryWaveSpeed, forKey: StorageKey.secondaryWaveSpeed)
        defaults.set(primaryWaveOpacity, forKey: StorageKey.primaryWaveOpacity)
        defaults.set(secondaryWaveOpacity, forKey: StorageKey.secondaryWaveOpacity)

        defaults.set(primaryHue, forKey: StorageKey.primaryHue)
        defaults.set(secondaryHue, forKey: StorageKey.secondaryHue)
        defaults.set(waveCount, forKey: StorageKey.waveCount)

        defaults.set(bloomEnabled, forKey: StorageKey.bloomEnabled)
        defaults.set(bloomStrength, forKey: StorageKey.bloomStrength)
        defaults.set(chromaticAberrationEnabled, forKey: StorageKey.chromaticAberrationEnabled)
        defaults.set(chromaticAberrationStrength, forKey: StorageKey.chromaticAberrationStrength)
        defaults.set(blurEnabled, forKey: StorageKey.blurEnabled)
        defaults.set(blurRadius, forKey: StorageKey.blurRadius)

        defaults.set(shaderTransparency, forKey: StorageKey.shaderTransparency)
        defaults.set(shaderStyle.rawValue, forKey: StorageKey.shaderStyle)
    }

    private func bool(for key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }

    private func double(for key: String, defaultValue: Double) -> Double {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.double(forKey: key)
    }

    private func int(for key: String, defaultValue: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.integer(forKey: key)
    }

    private func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(upper, max(lower, value))
    }
}

// Reuse naming expected by the existing Metal background implementation.
typealias BackgroundSettings = BackgroundProfile
