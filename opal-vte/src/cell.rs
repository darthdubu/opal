use crate::color::Color;
use bitflags::bitflags;

bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
    pub struct Flags: u32 {
        const BOLD = 1 << 0;
        const ITALIC = 1 << 1;
        const UNDERLINE = 1 << 2;
        const STRIKETHROUGH = 1 << 3;
        const INVERSE = 1 << 4;
        const DIM = 1 << 5;
        const HIDDEN = 1 << 6;
        const WRAPLINE = 1 << 7;
        const WIDE = 1 << 8;
        const WIDE_SPACER = 1 << 9;
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Default)]
pub struct Cell {
    pub c: char,
    pub fg: Color,
    pub bg: Color,
    pub flags: Flags,
}

impl Cell {
    pub fn new(c: char) -> Self {
        Self {
            c,
            fg: Color::default(),
            bg: Color::default(),
            flags: Flags::empty(),
        }
    }

    pub fn with_fg(mut self, fg: Color) -> Self {
        self.fg = fg;
        self
    }

    pub fn with_bg(mut self, bg: Color) -> Self {
        self.bg = bg;
        self
    }

    pub fn with_flags(mut self, flags: Flags) -> Self {
        self.flags = flags;
        self
    }

    pub fn is_wide(&self) -> bool {
        self.flags.contains(Flags::WIDE)
    }

    pub fn reset(&mut self) {
        self.c = ' ';
        self.fg = Color::default();
        self.bg = Color::default();
        self.flags = Flags::empty();
    }
}
