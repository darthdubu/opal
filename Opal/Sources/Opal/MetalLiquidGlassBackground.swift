import SwiftUI
import MetalKit
import QuartzCore

/// Metal-based liquid glass background that maps 1:1 with Background settings.
struct MetalLiquidGlassBackground: NSViewRepresentable {
    enum PreviewFocus: Equatable {
        case none
        case bloom
        case chromatic
        case blur
        case all
    }

    @ObservedObject var settings: BackgroundSettings
    var previewFocus: PreviewFocus = .none

    func makeCoordinator() -> Coordinator {
        Coordinator(settings: settings, previewFocus: previewFocus)
    }

    func makeNSView(context: Context) -> LiquidGlassMTKView {
        let metalView = LiquidGlassMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.delegate = context.coordinator
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.framebufferOnly = false
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60

        context.coordinator.attach(to: metalView)
        return metalView
    }

    func updateNSView(_ nsView: LiquidGlassMTKView, context: Context) {
        context.coordinator.settings = settings
        context.coordinator.previewFocus = previewFocus
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        struct Uniforms {
            var time: Float
            var primaryHue: Float
            var secondaryHue: Float
            var primarySpeed: Float
            var secondarySpeed: Float
            var waveCount: Float
            var opacity: Float
            var shaderStyle: Float
            var bloomEnabled: Float
            var bloomStrength: Float
            var chromaticEnabled: Float
            var chromaticStrength: Float
            var blurEnabled: Float
            var blurRadius: Float
            var animationEnabled: Float
            var padding: Float
        }

        var settings: BackgroundSettings
        var previewFocus: PreviewFocus

        private weak var view: MTKView?
        private var device: MTLDevice?
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var vertexBuffer: MTLBuffer?
        private var uniformBuffer: MTLBuffer?

        private var startTime: CFTimeInterval = CACurrentMediaTime()
        private var frozenTime: Float = 0

        init(settings: BackgroundSettings, previewFocus: PreviewFocus) {
            self.settings = settings
            self.previewFocus = previewFocus
        }

        func attach(to view: MTKView) {
            self.view = view
            guard let device = view.device else { return }
            self.device = device

            commandQueue = device.makeCommandQueue()
            uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)

            let vertices: [Float] = [
                -1, -1, 0, 0,
                 1, -1, 1, 0,
                -1,  1, 0, 1,
                -1,  1, 0, 1,
                 1, -1, 1, 0,
                 1,  1, 1, 1,
            ]
            vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<Float>.stride,
                options: .storageModeShared
            )

            buildPipeline(device: device, pixelFormat: view.colorPixelFormat)
        }

        private func buildPipeline(device: MTLDevice, pixelFormat: MTLPixelFormat) {
            let source = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexIn {
                float2 position [[attribute(0)]];
                float2 uv [[attribute(1)]];
            };

            struct VertexOut {
                float4 position [[position]];
                float2 uv;
            };

            struct Uniforms {
                float time;
                float primaryHue;
                float secondaryHue;
                float primarySpeed;
                float secondarySpeed;
                float waveCount;
                float opacity;
                float shaderStyle;
                float bloomEnabled;
                float bloomStrength;
                float chromaticEnabled;
                float chromaticStrength;
                float blurEnabled;
                float blurRadius;
                float animationEnabled;
                float padding;
            };

            vertex VertexOut liquidGlassVertex(VertexIn in [[stage_in]]) {
                VertexOut out;
                out.position = float4(in.position, 0.0, 1.0);
                out.uv = in.uv;
                return out;
            }

            float3 hsv2rgb(float3 c) {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float hashNoise(float2 p) {
                return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
            }

            float layeredWave(float x, float time, float speed, float phase, float amplitude, float a, float b, float c) {
                float w1 = sin(x * a + time * speed + phase) * amplitude;
                float w2 = sin(x * b + time * speed * 0.62 + phase * 0.7) * (amplitude * 0.55);
                float w3 = sin(x * c + time * speed * 1.18 + phase * 0.35) * (amplitude * 0.35);
                return w1 + w2 + w3;
            }

            float3 sampleAurora(float2 uv, constant Uniforms& u, float time) {
                int layers = max(1, min(int(u.waveCount), 8));
                float3 color = float3(0.0);

                for (int i = 0; i < 8; i++) {
                    if (i >= layers) {
                        break;
                    }

                    float layer = float(i);
                    float t = layer / max(float(layers - 1), 1.0);
                    float hue = mix(u.primaryHue, u.secondaryHue, t);
                    float3 waveColor = hsv2rgb(float3(hue, 0.8, 0.92));

                    float offset = layer * 1.5;
                    float baseY = 0.16 + layer * 0.16;
                    float wave = layeredWave(
                        uv.x,
                        time,
                        u.primarySpeed * (0.78 + layer * 0.08),
                        offset,
                        0.085 + layer * 0.004,
                        12.57,
                        21.36,
                        3.77
                    );

                    float crest = baseY + wave;
                    float band = 1.0 - smoothstep(crest - 0.11, crest + 0.2, uv.y);
                    float feather = smoothstep(0.0, 0.35, crest - uv.y + 0.15);
                    float layerOpacity = max(0.025, 0.18 - layer * 0.017);
                    color += waveColor * band * feather * layerOpacity;
                }

                float secondaryWave = layeredWave(uv.x, time, u.secondarySpeed * 0.92, 2.35, 0.06, 10.4, 17.0, 2.6);
                float3 secondaryColor = hsv2rgb(float3(u.secondaryHue, 0.72, 0.86));
                float secondaryBand = 1.0 - smoothstep((0.38 + secondaryWave) - 0.09, (0.38 + secondaryWave) + 0.16, uv.y);
                color += secondaryColor * secondaryBand * 0.11;

                return color;
            }

            float3 sampleOcean(float2 uv, constant Uniforms& u, float time) {
                int layers = max(1, min(int(u.waveCount), 8));
                float3 color = float3(0.0);

                for (int i = 0; i < 8; i++) {
                    if (i >= layers) {
                        break;
                    }

                    float layer = float(i);
                    float t = layer / max(float(layers - 1), 1.0);
                    float hue = mix(u.primaryHue, u.secondaryHue, t);
                    float3 waveColor = hsv2rgb(float3(hue, 0.74, 0.86));

                    float baseY = 0.21 + layer * 0.1;
                    float wave = sin(uv.x * (3.2 + layer * 0.45) + time * (u.primarySpeed * (0.45 + layer * 0.08)) + layer) * (0.06 + layer * 0.005);
                    wave += sin(uv.x * 1.6 - time * (u.secondarySpeed * 0.32) + layer * 1.9) * 0.025;

                    float band = 1.0 - smoothstep(baseY + wave - 0.08, baseY + wave + 0.15, uv.y);
                    color += waveColor * band * (0.17 - layer * 0.017);
                }

                return color;
            }

            float3 sampleScene(float2 uv, constant Uniforms& u, float time) {
                float3 color = float3(0.015, 0.03, 0.075);
                float gradient = smoothstep(1.0, -0.15, uv.y);
                color += float3(0.018, 0.03, 0.05) * gradient * 0.35;

                if (u.shaderStyle < 0.5) {
                    color += sampleAurora(uv, u, time);
                } else {
                    color += sampleOcean(uv, u, time);
                }

                float topSpecular = exp(-pow(max(uv.y - 0.02, 0.0) * 16.0, 2.0)) * 0.08;
                color += float3(0.72, 0.84, 1.0) * topSpecular;

                float shimmer = hashNoise(uv * 750.0 + time * 0.4) * 0.018;
                color += shimmer;

                return max(color, 0.0);
            }

            float3 gaussianBlur(float2 uv, constant Uniforms& u, float time) {
                float3 acc = float3(0.0);
                float total = 0.0;

                float radius = max(u.blurRadius, 0.00015);

                for (int x = -2; x <= 2; x++) {
                    for (int y = -2; y <= 2; y++) {
                        float2 offset = float2(float(x), float(y)) * radius;
                        float2 sampleUv = clamp(uv + offset, 0.0, 1.0);
                        float weight = exp(-float(x * x + y * y) / 4.0);

                        acc += sampleScene(sampleUv, u, time) * weight;
                        total += weight;
                    }
                }

                return acc / max(total, 0.0001);
            }

            float3 chromaticAberration(float2 uv, constant Uniforms& u, float time) {
                float2 center = float2(0.5, 0.5);
                float2 delta = uv - center;
                float distance = length(delta);
                float2 dir = delta / max(distance, 0.0001);
                float offset = u.chromaticStrength * (0.4 + distance * 1.8);

                float3 red = sampleScene(clamp(uv - dir * offset, 0.0, 1.0), u, time);
                float3 green = sampleScene(uv, u, time);
                float3 blue = sampleScene(clamp(uv + dir * offset, 0.0, 1.0), u, time);

                return float3(red.r, green.g, blue.b);
            }

            fragment float4 liquidGlassFragment(VertexOut in [[stage_in]],
                                                constant Uniforms& u [[buffer(0)]]) {
                float2 uv = in.uv;
                float time = u.time;

                float3 color = sampleScene(uv, u, time);

                if (u.blurEnabled > 0.5) {
                    float3 blurred = gaussianBlur(uv, u, time);
                    color = mix(color, blurred, 0.65);
                }

                if (u.chromaticEnabled > 0.5) {
                    float3 ca = chromaticAberration(uv, u, time);
                    color = mix(color, ca, 0.9);
                }

                if (u.bloomEnabled > 0.5) {
                    float brightness = dot(color, float3(0.2126, 0.7152, 0.0722));
                    float glow = smoothstep(0.28, 1.0, brightness);
                    color += color * glow * u.bloomStrength * 0.45;
                }

                color = clamp(color, 0.0, 1.2);

                return float4(color, clamp(u.opacity, 0.0, 1.0));
            }
            """

            do {
                let library = try device.makeLibrary(source: source, options: nil)
                guard let vertex = library.makeFunction(name: "liquidGlassVertex"),
                      let fragment = library.makeFunction(name: "liquidGlassFragment") else {
                    return
                }

                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = vertex
                descriptor.fragmentFunction = fragment
                descriptor.colorAttachments[0].pixelFormat = pixelFormat
                descriptor.colorAttachments[0].isBlendingEnabled = true
                descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

                let vertexDescriptor = MTLVertexDescriptor()
                vertexDescriptor.attributes[0].format = .float2
                vertexDescriptor.attributes[0].offset = 0
                vertexDescriptor.attributes[0].bufferIndex = 0
                vertexDescriptor.attributes[1].format = .float2
                vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
                vertexDescriptor.attributes[1].bufferIndex = 0
                vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 4
                descriptor.vertexDescriptor = vertexDescriptor

                pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                print("Failed to create liquid glass pipeline: \(error)")
            }
        }

        private func makeUniforms() -> Uniforms {
            let current = Float(CACurrentMediaTime() - startTime)
            if settings.animationEnabled {
                frozenTime = current
            }

            let previewBloom = previewFocus == .bloom || previewFocus == .all
            let previewChromatic = previewFocus == .chromatic || previewFocus == .all
            let previewBlur = previewFocus == .blur || previewFocus == .all

            let bloomEnabled = settings.bloomEnabled || previewBloom
            let chromaticEnabled = settings.chromaticAberrationEnabled || previewChromatic
            let blurEnabled = settings.blurEnabled || previewBlur

            let bloomStrength = previewBloom
                ? max(Float(settings.bloomStrength), 1.1) * 1.6
                : Float(settings.bloomStrength)
            let chromaticStrength = previewChromatic
                ? max(Float(settings.chromaticAberrationStrength), 0.012)
                : Float(settings.chromaticAberrationStrength)
            let blurRadius = previewBlur
                ? max(Float(settings.blurRadius), 0.012)
                : Float(settings.blurRadius)

            // Slider is expressed as transparency (%), while shader needs opacity (alpha).
            let opacity = max(0.0, min(1.0, 1.0 - Float(settings.shaderTransparency / 100.0)))

            return Uniforms(
                time: frozenTime,
                primaryHue: Float(settings.primaryHue / 360.0),
                secondaryHue: Float(settings.secondaryHue / 360.0),
                primarySpeed: Float(settings.primaryWaveSpeed) * 35.0,
                secondarySpeed: Float(settings.secondaryWaveSpeed) * 35.0,
                waveCount: Float(settings.waveCount),
                opacity: opacity,
                shaderStyle: settings.shaderStyle == .aurora ? 0.0 : 1.0,
                bloomEnabled: bloomEnabled ? 1.0 : 0.0,
                bloomStrength: bloomStrength,
                chromaticEnabled: chromaticEnabled ? 1.0 : 0.0,
                chromaticStrength: chromaticStrength,
                blurEnabled: blurEnabled ? 1.0 : 0.0,
                blurRadius: blurRadius,
                animationEnabled: settings.animationEnabled ? 1.0 : 0.0,
                padding: 0.0
            )
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let queue = commandQueue,
                  let pipeline = pipelineState,
                  let vertices = vertexBuffer,
                  let uniforms = uniformBuffer else {
                return
            }

            var values = makeUniforms()
            memcpy(uniforms.contents(), &values, MemoryLayout<Uniforms>.stride)

            guard let commandBuffer = queue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertices, offset: 0, index: 0)
            encoder.setFragmentBuffer(uniforms, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            _ = size
        }
    }
}

final class LiquidGlassMTKView: MTKView {
    override var acceptsFirstResponder: Bool {
        false
    }

    override var isOpaque: Bool {
        false
    }
}
