import SwiftUI
import Combine

class WindowSettings: ObservableObject {
    static let shared = WindowSettings()
    
    @Published var backgroundOpacity: Double = 0.2 {
        didSet {
            BackgroundSettings.shared.backgroundOpacity = backgroundOpacity
            BackgroundSettings.shared.glassOpacity = backgroundOpacity + 0.05
        }
    }
    
    @Published var blurRadius: Double = 10.0
    
    private init() {}
}
