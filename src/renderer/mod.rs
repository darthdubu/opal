use std::collections::HashMap;

pub struct GlyphInfo {
    pub u0: f32,
    pub v0: f32,
    pub u1: f32,
    pub v1: f32,
    pub width: f32,
    pub height: f32,
    pub bearing_x: f32,
    pub bearing_y: f32,
    pub advance: f32,
}

pub struct GlyphAtlas {
    glyphs: HashMap<char, GlyphInfo>,
    width: u32,
    height: u32,
    cell_width: u32,
    cell_height: u32,
}

impl GlyphAtlas {
    pub fn new() -> Self {
        Self {
            glyphs: HashMap::new(),
            width: 2048,
            height: 2048,
            cell_width: 8,
            cell_height: 16,
        }
    }

    pub fn get_glyph(&self, c: char) -> Option<&GlyphInfo> {
        self.glyphs.get(&c)
    }

    pub fn insert_glyph(&mut self, c: char, info: GlyphInfo) {
        self.glyphs.insert(c, info);
    }

    pub fn set_cell_size(&mut self, width: u32, height: u32) {
        self.cell_width = width;
        self.cell_height = height;
    }
}

pub struct Vertex {
    pub x: f32,
    pub y: f32,
    pub u: f32,
    pub v: f32,
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Vertex {
    pub fn new(x: f32, y: f32, u: f32, v: f32, r: f32, g: f32, b: f32, a: f32) -> Self {
        Self {
            x,
            y,
            u,
            v,
            r,
            g,
            b,
            a,
        }
    }
}

pub struct Renderer {
    atlas: GlyphAtlas,
    background_color: [f32; 4],
    blur_radius: f32,
    background_alpha: f32,
    initialized: bool,
    font_size: f32,
    cell_width: u32,
    cell_height: u32,
}

impl Renderer {
    pub fn new() -> Self {
        Self {
            atlas: GlyphAtlas::new(),
            background_color: [0.118, 0.118, 0.118, 0.85],
            blur_radius: 20.0,
            background_alpha: 0.85,
            initialized: true,
            font_size: 14.0,
            cell_width: 8,
            cell_height: 16,
        }
    }

    pub fn init(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        self.initialized = true;
        Ok(())
    }

    pub fn set_background_color(&mut self, r: f32, g: f32, b: f32, a: f32) {
        self.background_color = [r, g, b, a];
    }

    pub fn set_blur_radius(&mut self, radius: f32) {
        self.blur_radius = radius;
    }

    pub fn set_background_alpha(&mut self, alpha: f32) {
        self.background_alpha = alpha;
        self.background_color[3] = alpha;
    }

    pub fn set_font_size(&mut self, size: f32) {
        self.font_size = size;
        self.cell_height = (size * 1.2) as u32;
        self.cell_width = (size * 0.6) as u32;
        self.atlas.set_cell_size(self.cell_width, self.cell_height);
    }

    pub fn get_cell_size(&self) -> (u32, u32) {
        (self.cell_width, self.cell_height)
    }

    pub fn render_terminal(&mut self, _screen: &super::terminal::screen::Screen) {}

    pub fn is_initialized(&self) -> bool {
        self.initialized
    }

    pub fn atlas(&self) -> &GlyphAtlas {
        &self.atlas
    }

    pub fn atlas_mut(&mut self) -> &mut GlyphAtlas {
        &mut self.atlas
    }

    pub fn get_background_color(&self) -> [f32; 4] {
        self.background_color
    }

    pub fn get_blur_radius(&self) -> f32 {
        self.blur_radius
    }
}

impl Default for Renderer {
    fn default() -> Self {
        Self::new()
    }
}
