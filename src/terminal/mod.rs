pub mod color;
pub mod input;
pub mod pty;
pub mod screen;
pub mod vte;

pub struct Terminal {
    screen: screen::Screen,
    pty: pty::Pty,
}

impl Terminal {
    pub fn new() -> Self {
        Self {
            screen: screen::Screen::new(80, 24),
            pty: pty::Pty::new(),
        }
    }

    pub fn resize(&mut self, cols: u16, rows: u16) {
        self.screen.resize(cols, rows);
        self.pty.resize(cols, rows);
    }
}
