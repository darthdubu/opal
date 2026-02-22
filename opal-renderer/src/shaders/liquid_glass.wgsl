// Liquid Glass background shader
// Creates a glass morphism effect with aurora waves

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var out: VertexOutput;
    
    // Full-screen quad
    let vertices = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 1.0, -1.0),
        vec2<f32>(-1.0,  1.0),
        vec2<f32>(-1.0,  1.0),
        vec2<f32>( 1.0, -1.0),
        vec2<f32>( 1.0,  1.0)
    );
    
    let pos = vertices[vertex_index];
    out.position = vec4<f32>(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    
    return out;
}

// Simplex noise function for organic patterns
fn hash22(p: vec2<f32>) -> vec2<f32> {
    let n = sin(dot(p, vec2<f32>(41.0, 289.0)));
    return fract(vec2<f32>(262144.0, 32768.0) * n);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    let a = hash22(i).x;
    let b = hash22(i + vec2<f32>(1.0, 0.0)).x;
    let c = hash22(i + vec2<f32>(0.0, 1.0)).x;
    let d = hash22(i + vec2<f32>(1.0, 1.0)).x;
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    let time = 0.0; // Will be passed as uniform
    
    // Deep space base
    var color = vec3<f32>(0.05, 0.06, 0.08);
    
    // Aurora wave 1 - cyan/blue
    let wave1 = sin(uv.x * 4.0 + time * 0.5) * 0.3;
    let wave2 = sin(uv.y * 3.0 + time * 0.3) * 0.2;
    let aurora1 = smoothstep(0.4, 0.6, uv.y + wave1 + wave2);
    color += vec3<f32>(0.1, 0.3, 0.5) * aurora1 * 0.15;
    
    // Aurora wave 2 - purple
    let wave3 = sin(uv.x * 3.0 - time * 0.4) * 0.25;
    let wave4 = sin(uv.y * 4.0 - time * 0.2) * 0.15;
    let aurora2 = smoothstep(0.3, 0.7, uv.y + wave3 + wave4);
    color += vec3<f32>(0.3, 0.1, 0.4) * aurora2 * 0.1;
    
    // Noise shimmer
    let shimmer = noise(uv * 10.0 + time * 0.1) * 0.03;
    color += vec3<f32>(shimmer);
    
    // Glass material overlay
    let glass_alpha = 0.85;
    
    return vec4<f32>(color, glass_alpha);
}
