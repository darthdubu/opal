use glyphon::{
    Attrs, Buffer, Cache, Color as GlyphonColor, Family, FontSystem, Metrics, Resolution, SwashCache,
    TextArea, TextAtlas, TextBounds, TextRenderer, Viewport,
};
use wgpu::{CommandEncoder, Device, Queue, TextureFormat, TextureView};

/// Manages text rendering using glyphon
pub struct TextRenderManager {
    font_system: FontSystem,
    swash_cache: SwashCache,
    cache: Cache,
    atlas: TextAtlas,
    renderer: TextRenderer,
    viewport: Viewport,
    buffer: Buffer,
}

impl TextRenderManager {
    pub fn new(device: &Device, queue: &Queue, format: TextureFormat) -> Self {
        let mut font_system = FontSystem::new();
        let swash_cache = SwashCache::new();
        let cache = Cache::new(device);
        let mut atlas = TextAtlas::new(device, queue, &cache, format);
        let renderer = TextRenderer::new(&mut atlas, device, wgpu::MultisampleState::default(), None);
        let viewport = Viewport::new(device, &cache);
        let metrics = Metrics::new(14.0, 20.0);
        let buffer = Buffer::new(&mut font_system, metrics);

        Self {
            font_system,
            swash_cache,
            cache,
            atlas,
            renderer,
            viewport,
            buffer,
        }
    }

    pub fn resize(&mut self, queue: &Queue, width: u32, height: u32) {
        self.viewport.update(queue, Resolution { width, height });
    }

    /// Prepare text for rendering
    pub fn prepare_text(
        &mut self,
        device: &Device,
        queue: &Queue,
        text: &str,
        x: f32,
        y: f32,
        color: [u8; 4],
    ) {
        // Set text in buffer
        self.buffer.set_text(
            &mut self.font_system,
            text,
            &Attrs::new().family(Family::Monospace),
            glyphon::Shaping::Advanced,
            None,
        );

        // Wrap text at specified width (infinite for terminal)
        self.buffer.shape_until_scroll(&mut self.font_system, false);
    }

    /// Render prepared text
    pub fn render<'pass>(
        &'pass mut self,
        device: &Device,
        queue: &Queue,
        encoder: &mut CommandEncoder,
        texture_view: &'pass TextureView,
    ) -> anyhow::Result<()> {
        self.renderer.prepare(
            device,
            queue,
            &mut self.font_system,
            &mut self.atlas,
            &self.viewport,
            [TextArea {
                buffer: &self.buffer,
                left: 0.0,
                top: 0.0,
                scale: 1.0,
                bounds: TextBounds {
                    left: 0,
                    top: 0,
                    right: i32::MAX,
                    bottom: i32::MAX,
                },
                default_color: GlyphonColor::rgb(255, 255, 255),
                custom_glyphs: &[],
            }],
            &mut self.swash_cache,
        )?;

        // Render text
        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("Text Render Pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: texture_view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Load, // Preserve existing content
                    store: wgpu::StoreOp::Store,
                },
                depth_slice: None,
            })],
            depth_stencil_attachment: None,
            timestamp_writes: None,
            occlusion_query_set: None,
            multiview_mask: None,
        });

        self.renderer
            .render(&self.atlas, &self.viewport, &mut render_pass)?;

        Ok(())
    }

    /// Render a single line of terminal text at the specified position
    pub fn render_terminal_line(
        &mut self,
        device: &Device,
        queue: &Queue,
        line_text: &str,
        row: usize,
        col_offset: f32,
        row_offset: f32,
        char_width: f32,
        line_height: f32,
    ) {
        let x = col_offset * char_width;
        let y = row_offset + row as f32 * line_height;

        self.prepare_text(device, queue, line_text, x, y, [255, 255, 255, 255]);
    }
}

/// Color conversion utilities
pub fn color_to_glyphon_color(r: u8, g: u8, b: u8) -> GlyphonColor {
    GlyphonColor::rgb(r, g, b)
}

pub fn indexed_color_to_rgb(index: u8) -> [u8; 3] {
    // Standard ANSI 16 colors
    match index {
        0 => [0, 0, 0],       // Black
        1 => [205, 49, 49],   // Red
        2 => [13, 188, 121],  // Green
        3 => [229, 229, 16],  // Yellow
        4 => [36, 114, 200],  // Blue
        5 => [188, 63, 188],  // Magenta
        6 => [17, 168, 205],  // Cyan
        7 => [229, 229, 229], // White
        // Bright colors
        8 => [77, 77, 77],     // Bright Black
        9 => [255, 107, 107],  // Bright Red
        10 => [83, 252, 165],  // Bright Green
        11 => [255, 255, 112], // Bright Yellow
        12 => [90, 158, 255],  // Bright Blue
        13 => [255, 113, 255], // Bright Magenta
        14 => [66, 210, 255],  // Bright Cyan
        15 => [255, 255, 255], // Bright White
        // 256 color palette (simplified - grayscale and RGB cube)
        16..=231 => {
            // RGB cube
            let idx = index - 16;
            let r = (idx / 36) * 51;
            let g = ((idx % 36) / 6) * 51;
            let b = (idx % 6) * 51;
            [r, g, b]
        }
        232..=255 => {
            // Grayscale
            let gray = 8 + (index - 232) * 10;
            [gray, gray, gray]
        }
    }
}
