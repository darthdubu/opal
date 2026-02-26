import SwiftUI

struct LiquidGlassBackground: View {
    @ObservedObject var profile: BackgroundProfile
    var previewFocus: MetalLiquidGlassBackground.PreviewFocus = .none

    var body: some View {
        ZStack {
            if profile.useMetalShader {
                MetalLiquidGlassBackground(settings: profile, previewFocus: previewFocus)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.17, blue: 0.32),
                        Color(red: 0.07, green: 0.09, blue: 0.2),
                        Color(red: 0.03, green: 0.05, blue: 0.12),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(max(0.1, 1.0 - profile.shaderTransparency / 100.0))
            }
        }
        .background(Color.clear)
    }
}
