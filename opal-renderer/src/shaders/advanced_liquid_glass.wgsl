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

@group(0) @binding(2)
var<uniform> uniforms: Uniforms;

struct Uniforms {
    time: f32,
    aberration_strength: f32,
    bloom_strength: f32,
    blur_radius: f32,
}

// Chromatic aberration function
fn chromatic_aberration(uv: vec2<f32>, strength: f32) -> vec3<f32> {
    let center = vec2<f32>(0.5, 0.5);
    let direction = uv - center;
    let distance_from_center = length(direction);
    let normalized_direction = direction / max(distance_from_center, 0.0001);
    
    // Sample each color channel at slightly different positions
    let r_offset = -normalized_direction * strength * distance_from_center;
    let g_offset = vec2<f32>(0.0, 0.0);
    let b_offset = normalized_direction * strength * distance_from_center;
    
    let r = textureSample(input_texture, input_sampler, uv + r_offset).r;
    let g = textureSample(input_texture, input_sampler, uv + g_offset).g;
    let b = textureSample(input_texture, input_sampler, uv + b_offset).b;
    
    return vec3<f32>(r, g, b);
}

// Gaussian blur function
fn gaussian_blur(uv: vec2<f32>, radius: f32) -> vec4<f32> {
    var color = vec4<f32>(0.0);
    var total_weight = 0.0;
    
    // 5x5 kernel
    for (var x: i32 = -2; x <= 2; x = x + 1) {
        for (var y: i32 = -2; y <= 2; y = y + 1) {
            let offset = vec2<f32>(f32(x) * radius, f32(y) * radius);
            let sample = textureSample(input_texture, input_sampler, uv + offset);
            
            // Gaussian weight
            let distance = f32(x * x + y * y);
            let weight = exp(-f32(distance) / 8.0);
            
            color = color + sample * weight;
            total_weight = total_weight + weight;
        }
    }
    
    return color / total_weight;
}

// Bloom effect by extracting bright areas and blurring
fn bloom(uv: vec2<f32>, strength: f32) -> vec3<f32> {
    let blurred = gaussian_blur(uv, 0.005).rgb;
    let original = textureSample(input_texture, input_sampler, uv).rgb;
    
    // Extract bright areas
    let brightness = dot(blurred, vec3<f32>(0.2126, 0.7152, 0.0722));
    let bright_areas = blurred * smoothstep(0.5, 1.0, brightness);
    
    // Add bloom to original
    return original + bright_areas * strength;
}

// Subtle distortion based on time for "liquid" feel
fn liquid_distortion(uv: vec2<f32>, time: f32) -> vec2<f32> {
    let wave = sin(uv.y * 10.0 + time * 2.0) * 0.002;
    let wave2 = cos(uv.x * 8.0 + time * 1.5) * 0.002;
    
    return uv + vec2<f32>(wave, wave2);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = liquid_distortion(in.uv, uniforms.time);
    
    // Apply chromatic aberration
    var color = chromatic_aberration(uv, uniforms.aberration_strength);
    
    // Apply bloom
    color = bloom(uv, uniforms.bloom_strength);
    
    // Apply frosted glass effect (blur + overlay)
    let blurred = gaussian_blur(uv, uniforms.blur_radius).rgb;
    
    // Frosted glass overlay
    let glass_color = vec3<f32>(1.0, 1.0, 1.0);
    let glass_amount = 0.08;
    
    color = mix(color, blurred * 0.9 + glass_color * 0.1, glass_amount);
    
    // Add subtle vignette for depth
    let center = vec2<f32>(0.5, 0.5);
    let dist_from_center = length(in.uv - center);
    let vignette = 1.0 - dist_from_center * 0.3;
    
    return vec4<f32>(color * vignette, 1.0);
}
