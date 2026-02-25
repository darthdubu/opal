import SwiftUI
import OpalCore
import MetalKit
import Carbon.HIToolbox

struct TerminalMetalView: NSViewRepresentable {
    @ObservedObject var viewModel: TerminalViewModel
    
    func makeNSView(context: Context) -> TerminalMTKView {
        let metalView = TerminalMTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.delegate = context.coordinator
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.framebufferOnly = false
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.viewModel = viewModel
        
        if let device = metalView.device {
            let devicePtr = unsafeBitCast(device, to: UInt64.self)
            _ = context.coordinator.renderer.initializeWithMetalDevice(devicePtr: devicePtr)
        }
        
        // Make the view accept first responder so it can receive keyboard events
        DispatchQueue.main.async {
            metalView.window?.makeFirstResponder(metalView)
        }
        
        return metalView
    }
    
    func updateNSView(_ nsView: TerminalMTKView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: TerminalMetalView
        var metalDevice: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var renderer: RendererHandle
        var terminalRenderer: OpalCore.TerminalRenderer
        
        init(_ parent: TerminalMetalView) {
            self.parent = parent
            self.renderer = RendererHandle()
            self.terminalRenderer = TerminalRenderer(handle: renderer)
            super.init()
            
            if let device = MTLCreateSystemDefaultDevice() {
                self.metalDevice = device
                self.commandQueue = device.makeCommandQueue()
            }
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandQueue = commandQueue else { return }
            
            updateTerminalContent()
            _ = terminalRenderer.render()
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            
            renderEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer.resize(width: UInt32(size.width), height: UInt32(size.height))
        }
        
        private func updateTerminalContent() {
            guard let terminalHandle = parent.viewModel.terminalHandle else { return }
            
            let rows = Int(terminalHandle.rows())
            let cols = Int(terminalHandle.cols())
            
            var renderRows: [RenderRow] = []
            
            for row in 0..<rows {
                var cells: [RenderCell] = []
                for col in 0..<cols {
                    if let cell = terminalHandle.cellAt(col: UInt32(col), row: UInt32(row)) {
                        let fgColor = colorToRgba(cell.foreground)
                        let bgColor = colorToRgba(cell.background)
                        let renderCell = RenderCell(
                            content: cell.content,
                            fgColor: fgColor,
                            bgColor: bgColor
                        )
                        cells.append(renderCell)
                    }
                }
                renderRows.append(RenderRow(cells: cells))
            }
            
            terminalRenderer.updateContent(rows: renderRows)
        }
        
        private func colorToRgba(_ color: TerminalColor) -> Data {
            let bytes: [UInt8]
            switch color {
            case .default:
                bytes = [255, 255, 255, 255]
            case .black:
                bytes = [0, 0, 0, 255]
            case .red:
                bytes = [205, 49, 49, 255]
            case .green:
                bytes = [13, 188, 121, 255]
            case .yellow:
                bytes = [229, 229, 16, 255]
            case .blue:
                bytes = [36, 114, 200, 255]
            case .magenta:
                bytes = [188, 63, 188, 255]
            case .cyan:
                bytes = [17, 168, 205, 255]
            case .white:
                bytes = [229, 229, 229, 255]
            case .brightBlack:
                bytes = [100, 100, 100, 255]
            case .brightRed:
                bytes = [255, 100, 100, 255]
            case .brightGreen:
                bytes = [100, 255, 100, 255]
            case .brightYellow:
                bytes = [255, 255, 100, 255]
            case .brightBlue:
                bytes = [100, 100, 255, 255]
            case .brightMagenta:
                bytes = [255, 100, 255, 255]
            case .brightCyan:
                bytes = [100, 255, 255, 255]
            case .brightWhite:
                bytes = [255, 255, 255, 255]
            case .indexed:
                bytes = [128, 128, 128, 255]
            case .rgb:
                bytes = [200, 200, 200, 255]
            }
            return Data(bytes)
        }
    }
}

// Custom MTKView subclass that handles keyboard input
class TerminalMTKView: MTKView {
    weak var viewModel: TerminalViewModel?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        guard let viewModel = viewModel else { return }
        
        // Handle special keys
        switch event.keyCode {
        case UInt16(kVK_Return):
            viewModel.sendInput("\r")
        case UInt16(kVK_Delete):
            viewModel.sendInput("\u{7f}")
        case UInt16(kVK_Tab):
            viewModel.sendInput("\t")
        case UInt16(kVK_Space):
            viewModel.sendInput(" ")
        case UInt16(kVK_Escape):
            viewModel.sendInput("\u{1b}")
        case UInt16(kVK_UpArrow):
            viewModel.sendInput("\u{1b}[A")
        case UInt16(kVK_DownArrow):
            viewModel.sendInput("\u{1b}[B")
        case UInt16(kVK_RightArrow):
            viewModel.sendInput("\u{1b}[C")
        case UInt16(kVK_LeftArrow):
            viewModel.sendInput("\u{1b}[D")
        case UInt16(kVK_Home):
            viewModel.sendInput("\u{1b}[H")
        case UInt16(kVK_End):
            viewModel.sendInput("\u{1b}[F")
        case UInt16(kVK_PageUp):
            viewModel.sendInput("\u{1b}[5~")
        case UInt16(kVK_PageDown):
            viewModel.sendInput("\u{1b}[6~")
        default:
            if let characters = event.characters {
                viewModel.sendInput(characters)
            }
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        // Handle modifier keys if needed
    }
    
    override func mouseDown(with event: NSEvent) {
        // Make sure we become first responder when clicked
        window?.makeFirstResponder(self)
    }
}
