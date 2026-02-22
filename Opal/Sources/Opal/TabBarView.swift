import SwiftUI
import OpalCore

// TabBarView - placeholder for future tab implementation
// Currently using single terminal session
struct TabBarView: View {
    @ObservedObject var viewModel: TerminalViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Terminal")
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(6)
            
            Spacer()
            
            Button(action: { /* new tab - future implementation */ }) {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(.ultraThinMaterial)
    }
}

struct TabContainerView: View {
    @ObservedObject var viewModel: TerminalViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(viewModel: viewModel)
            TerminalContainerView(viewModel: viewModel)
        }
    }
}

// MARK: - Split View Support

enum SplitDirection {
    case horizontal
    case vertical
}

struct SplitView: View {
    let direction: SplitDirection
    let primary: AnyView
    let secondary: AnyView
    
    var body: some View {
        Group {
            switch direction {
            case .horizontal:
                HStack(spacing: 1) {
                    primary
                    Divider()
                    secondary
                }
            case .vertical:
                VStack(spacing: 1) {
                    primary
                    Divider()
                    secondary
                }
            }
        }
    }
}
