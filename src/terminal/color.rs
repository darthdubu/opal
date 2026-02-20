#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Rgb {
    pub fn new(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b }
    }

    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.trim_start_matches('#');
        if hex.len() != 6 {
            return None;
        }
        let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
        let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
        let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
        Some(Self { r, g, b })
    }
}

impl Default for Rgb {
    fn default() -> Self {
        Self { r: 0, g: 0, b: 0 }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Color {
    Default,
    Ansi(u8),
    Rgb(u8, u8, u8),
}

impl Default for Color {
    fn default() -> Self {
        Color::Default
    }
}

impl Color {
    pub fn to_rgb(&self, defaults: &ColorPalette) -> Rgb {
        match self {
            Color::Default => Rgb::default(),
            Color::Ansi(n) => defaults.get(*n),
            Color::Rgb(r, g, b) => Rgb::new(*r, *g, *b),
        }
    }
}

pub struct ColorPalette {
    pub ansi: [Rgb; 256],
}

impl ColorPalette {
    pub fn default_palette() -> Self {
        let mut ansi = [Rgb::default(); 256];

        // Standard colors (0-15)
        let standard = [
            (0, 0, 0),       // 0 black
            (205, 0, 0),     // 1 red
            (0, 205, 0),     // 2 green
            (205, 205, 0),   // 3 yellow
            (0, 0, 238),     // 4 blue
            (205, 0, 205),   // 5 magenta
            (0, 205, 205),   // 6 cyan
            (229, 229, 229), // 7 white
            (127, 127, 127), // 8 bright black
            (255, 0, 0),     // 9 bright red
            (0, 255, 0),     // 10 bright green
            (255, 255, 0),   // 11 bright yellow
            (92, 92, 255),   // 12 bright blue
            (255, 0, 255),   // 13 bright magenta
            (0, 255, 255),   // 14 bright cyan
            (255, 255, 255), // 15 bright white
        ];

        for (i, (r, g, b)) in standard.iter().enumerate() {
            ansi[i] = Rgb::new(*r, *g, *b);
        }

        // 216 colors (16-231) - 6x6x6 color cube
        let mut idx = 16;
        for r in 0..6 {
            for g in 0..6 {
                for b in 0..6 {
                    ansi[idx] = Rgb::new(
                        if r == 0 { 0 } else { 40 + r * 40 },
                        if g == 0 { 0 } else { 40 + g * 40 },
                        if b == 0 { 0 } else { 40 + b * 40 },
                    );
                    idx += 1;
                }
            }
        }

        // Grayscale (232-255)
        for i in 0..24 {
            let v = 8 + i * 10;
            ansi[232 + i] = Rgb::new(v as u8, v as u8, v as u8);
        }

        Self { ansi }
    }

    pub fn get(&self, n: u8) -> Rgb {
        self.ansi[n as usize]
    }
}

impl Default for ColorPalette {
    fn default() -> Self {
        Self::default_palette()
    }
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct CellAttributes {
    pub foreground: Color,
    pub background: Color,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub inverse: bool,
    pub hidden: bool,
    pub dim: bool,
    pub blink: bool,
}

impl CellAttributes {
    pub fn new() -> Self {
        Self::default()
    }
}
