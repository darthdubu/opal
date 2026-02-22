struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var out: VertexOutput;
    
    let x = f32(vertex_index % 2u) * 2.0 - 1.0;
    let y = f32(vertex_index / 2u) * 2.0 - 1.0;
    
    out.position = vec4<f32>(x, y, 0.0, 1.0);
    out.uv = vec2<f32>(x * 0.5 + 0.5, -y * 0.5 + 0.5);
    
    return out;
}

@group(0) @binding(0)
var input_texture: texture_2d<f32>;

@group(0) @binding(1)
var input_sampler: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color = textureSample(input_texture, input_sampler, in.uv);
    
    // Frosted glass effect - subtle blur
    let blur_radius = 0.003;
    var blurred = vec4<f32>(0.0);
    
    for (var x: i32 = -2; x <= 2; x = x + 1) {
        for (var y: i32 = -2; y <= 2; y = y + 1) {
            let offset = vec2<f32>(f32(x) * blur_radius, f32(y) * blur_radius);
            blurred = blurred + textureSample(input_texture, input_sampler, in.uv + offset);
        }
    }
    
    blurred = blurred / 25.0;
    
    // Add subtle white overlay for glass effect
    let glass_color = vec4<f32>(1.0, 1.0, 1.0, 0.15);
    
    return mix(blurred, glass_color, 0.1);
}
