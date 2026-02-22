import SwiftUI
import OpalCore

struct TabBarView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabButton(
                            title: tab.title,
                            isSelected: selectedTab == index,
                            onSelect: { selectedTab = index },
                            onClose: { viewModel.closeTab(id: tab.id) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Button(action: { viewModel.newTab() }) {
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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12))
                .lineLimit(1)
                
            if isSelected || isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .opacity(0.7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
}

struct TabContainerView: View {
    @ObservedObject var viewModel: TerminalViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(viewModel: viewModel, selectedTab: $viewModel.selectedTabIndex)
            
            if let tab = viewModel.currentTab {
                TerminalContainerView(viewModel: tab.viewModel)
                    .id(tab.id)
            } else {
                Text("No tabs open")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Tab Model

struct TerminalTab: Identifiable {
    let id = UUID()
    var title: String
    var viewModel: TerminalViewModel
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
