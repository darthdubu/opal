// Cursor shader - renders block, underline, or line cursor

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var out: VertexOutput;
    
    // Cursor quad - will be positioned via uniform buffer in production
    let vertices = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 1.0, -1.0),
        vec2<f32>(-1.0,  1.0),
        vec2<f32>(-1.0,  1.0),
        vec2<f32>( 1.0, -1.0),
        vec2<f32>( 1.0,  1.0)
    );
    
    out.position = vec4<f32>(vertices[vertex_index], 0.0, 1.0);
    
    return out;
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
    // Cursor color - white with slight transparency
    return vec4<f32>(1.0, 1.0, 1.0, 0.8);
}
