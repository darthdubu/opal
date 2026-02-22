#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum Color {
    #[default]
    Default,
    Indexed(u8),
    Rgb(u8, u8, u8),
}

impl Color {
    pub fn from_ansi_index(index: u8) -> Self {
        Color::Indexed(index)
    }

    pub fn from_rgb(r: u8, g: u8, b: u8) -> Self {
        Color::Rgb(r, g, b)
    }

    pub fn to_rgb(self) -> (u8, u8, u8) {
        match self {
            Color::Default => (0, 0, 0),
            Color::Indexed(i) => index_to_rgb(i),
            Color::Rgb(r, g, b) => (r, g, b),
        }
    }
}

fn index_to_rgb(index: u8) -> (u8, u8, u8) {
    match index {
        0..=15 => BASIC_COLORS[index as usize],
        16..=231 => {
            let index = index - 16;
            let r = (index / 36) * 51;
            let g = ((index % 36) / 6) * 51;
            let b = (index % 6) * 51;
            (r as u8, g as u8, b as u8)
        }
        232..=255 => {
            let gray = (index - 232) * 10 + 8;
            (gray, gray, gray)
        }
    }
}

const BASIC_COLORS: [(u8, u8, u8); 16] = [
    (0x00, 0x00, 0x00),
    (0x80, 0x00, 0x00),
    (0x00, 0x80, 0x00),
    (0x80, 0x80, 0x00),
    (0x00, 0x00, 0x80),
    (0x80, 0x00, 0x80),
    (0x00, 0x80, 0x80),
    (0xc0, 0xc0, 0xc0),
    (0x80, 0x80, 0x80),
    (0xff, 0x00, 0x00),
    (0x00, 0xff, 0x00),
    (0xff, 0xff, 0x00),
    (0x00, 0x00, 0xff),
    (0xff, 0x00, 0xff),
    (0x00, 0xff, 0xff),
    (0xff, 0xff, 0xff),
];
