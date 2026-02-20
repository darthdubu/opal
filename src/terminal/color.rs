#[derive(Clone, Copy, Debug)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Rgb {
    pub fn new(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b }
    }
}

#[derive(Clone, Copy, Debug)]
pub enum Color {
    Default,
    Ansi(u8),
    Rgb(u8, u8, u8),
}

impl Default for Rgb {
    fn default() -> Self {
        Self { r: 0, g: 0, b: 0 }
    }
}
