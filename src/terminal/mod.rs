pub mod color;
pub mod input;
pub mod pty;
pub mod screen;
pub mod vte;

use vte::VteHandler;

pub struct Terminal {
    pub screen: screen::Screen,
    pty: pty::Pty,
    pub bell: bool,
    parser: vte::VteParser,
}

impl Terminal {
    pub fn new() -> Self {
        Self {
            screen: screen::Screen::new(80, 24),
            pty: pty::Pty::new(),
            bell: false,
            parser: vte::VteParser::new(),
        }
    }

    pub fn resize(&mut self, cols: u16, rows: u16) {
        self.screen.resize(cols, rows);
        let _ = self.pty.resize(cols, rows);
    }

    pub fn spawn(&mut self, shell: Option<&str>) -> Result<u32, Box<dyn std::error::Error>> {
        self.pty.spawn(shell)
    }

    pub fn write(&self, data: &[u8]) -> Result<(), Box<dyn std::error::Error>> {
        self.pty.write(data)
    }

    pub fn process_byte(&mut self, byte: u8) {
        let screen = &mut self.screen;
        let bell = &mut self.bell;
        let mut handler = TerminalHandler { screen, bell };
        self.parser.parse(byte, &mut handler);
    }

    pub fn process_input(&mut self, data: &[u8]) {
        for &byte in data {
            self.process_byte(byte);
        }
    }

    pub fn clear_bell(&mut self) {
        self.bell = false;
    }

    pub fn get_cwd(&self) -> &std::path::PathBuf {
        self.pty.get_cwd()
    }
}

impl Default for Terminal {
    fn default() -> Self {
        Self::new()
    }
}

struct TerminalHandler<'a> {
    screen: &'a mut screen::Screen,
    bell: &'a mut bool,
}

impl<'a> VteHandler for TerminalHandler<'a> {
    fn print(&mut self, c: char) {
        self.screen.put_char(c);
    }

    fn del(&mut self) {
        self.screen.delete_char();
    }

    fn bs(&mut self) {
        self.screen.backspace();
    }

    fn ht(&mut self) {
        self.screen.tab();
    }

    fn lf(&mut self) {
        self.screen.linefeed();
    }

    fn vt(&mut self) {
        self.screen.linefeed();
    }

    fn ff(&mut self) {
        self.screen.linefeed();
    }

    fn cr(&mut self) {
        self.screen.carriage_return();
    }

    fn bel(&mut self) {
        *self.bell = true;
    }

    fn sos(&mut self) {}
    fn pm(&mut self) {}
    fn apc(&mut self) {}

    fn osc(&mut self, _params: &[u64], string: &str) {
        self.screen.set_title(string);
    }

    fn esc_0x30(&mut self) {}
    fn esc_0x31(&mut self) {}
    fn esc_0x32(&mut self) {}
    fn esc_0x34(&mut self) {}
    fn esc_0x35(&mut self) {}
    fn esc_0x36(&mut self) {}
    fn esc_0x37(&mut self) {}
    fn esc_0x38(&mut self) {}
    fn esc_0x3C(&mut self) {}
    fn esc_0x3D(&mut self) {}
    fn esc_0x3E(&mut self) {}
    fn esc_0x3F(&mut self) {}
    fn esc_0x40(&mut self) {}
    fn esc_alpha(&mut self, _byte: u8) {}

    fn csi(&mut self, final_byte: u8, params: &[u64], _intermediates: &[u8]) {
        match final_byte {
            b'A' => self.screen.cursor_up(params.first_or(1)),
            b'B' => self.screen.cursor_down(params.first_or(1)),
            b'C' => self.screen.cursor_forward(params.first_or(1)),
            b'D' => self.screen.cursor_back(params.first_or(1)),
            b'E' => self.screen.cursor_next_line(params.first_or(1)),
            b'F' => self.screen.cursor_previous_line(params.first_or(1)),
            b'G' => self.screen.cursor_absolute_col(params.first_or(1)),
            b'H' | b'f' => {
                let row = params.get(0).copied().unwrap_or(1);
                let col = params.get(1).copied().unwrap_or(1);
                self.screen.cursor_position(row, col);
            }
            b'J' => self.screen.erase_display(params.first_or(0)),
            b'K' => self.screen.erase_line(params.first_or(0)),
            b'L' => self.screen.insert_lines(params.first_or(1)),
            b'M' => self.screen.delete_lines(params.first_or(1)),
            b'P' => self.screen.delete_chars(params.first_or(1)),
            b'S' => self.screen.scroll_up(params.first_or(1)),
            b'T' => self.screen.scroll_down(params.first_or(1)),
            b'X' => self.screen.erase_chars(params.first_or(1)),
            b'd' => self.screen.cursor_absolute_row(params.first_or(1)),
            b'm' => self.screen.sgr(params),
            b'r' => {
                let top = params.get(0).copied().unwrap_or(1);
                let bottom = params
                    .get(1)
                    .copied()
                    .unwrap_or(self.screen.get_rows() as u64);
                self.screen.set_scroll_region(top, bottom);
            }
            b's' => self.screen.save_cursor(),
            b'u' => self.screen.restore_cursor(),
            b'h' => self.screen.handle_set_mode(params, true),
            b'l' => self.screen.handle_set_mode(params, false),
            _ => {}
        }
    }
}

impl VteHandler for Terminal {
    fn print(&mut self, c: char) {
        self.screen.put_char(c);
    }

    fn del(&mut self) {
        self.screen.delete_char();
    }

    fn bs(&mut self) {
        self.screen.backspace();
    }

    fn ht(&mut self) {
        self.screen.tab();
    }

    fn lf(&mut self) {
        self.screen.linefeed();
    }

    fn vt(&mut self) {
        self.screen.linefeed();
    }

    fn ff(&mut self) {
        self.screen.linefeed();
    }

    fn cr(&mut self) {
        self.screen.carriage_return();
    }

    fn bel(&mut self) {
        self.bell = true;
    }

    fn sos(&mut self) {}
    fn pm(&mut self) {}
    fn apc(&mut self) {}

    fn osc(&mut self, _params: &[u64], string: &str) {
        self.screen.set_title(string);
    }

    fn esc_0x30(&mut self) {}
    fn esc_0x31(&mut self) {}
    fn esc_0x32(&mut self) {}
    fn esc_0x34(&mut self) {}
    fn esc_0x35(&mut self) {}
    fn esc_0x36(&mut self) {}
    fn esc_0x37(&mut self) {}
    fn esc_0x38(&mut self) {}
    fn esc_0x3C(&mut self) {}
    fn esc_0x3D(&mut self) {}
    fn esc_0x3E(&mut self) {}
    fn esc_0x3F(&mut self) {}
    fn esc_0x40(&mut self) {}
    fn esc_alpha(&mut self, _byte: u8) {}

    fn csi(&mut self, final_byte: u8, params: &[u64], _intermediates: &[u8]) {
        match final_byte {
            b'A' => self.screen.cursor_up(params.first_or(1)),
            b'B' => self.screen.cursor_down(params.first_or(1)),
            b'C' => self.screen.cursor_forward(params.first_or(1)),
            b'D' => self.screen.cursor_back(params.first_or(1)),
            b'E' => self.screen.cursor_next_line(params.first_or(1)),
            b'F' => self.screen.cursor_previous_line(params.first_or(1)),
            b'G' => self.screen.cursor_absolute_col(params.first_or(1)),
            b'H' | b'f' => {
                let row = params.get(0).copied().unwrap_or(1);
                let col = params.get(1).copied().unwrap_or(1);
                self.screen.cursor_position(row, col);
            }
            b'J' => self.screen.erase_display(params.first_or(0)),
            b'K' => self.screen.erase_line(params.first_or(0)),
            b'L' => self.screen.insert_lines(params.first_or(1)),
            b'M' => self.screen.delete_lines(params.first_or(1)),
            b'P' => self.screen.delete_chars(params.first_or(1)),
            b'S' => self.screen.scroll_up(params.first_or(1)),
            b'T' => self.screen.scroll_down(params.first_or(1)),
            b'X' => self.screen.erase_chars(params.first_or(1)),
            b'd' => self.screen.cursor_absolute_row(params.first_or(1)),
            b'm' => self.screen.sgr(params),
            b'r' => {
                let top = params.get(0).copied().unwrap_or(1);
                let bottom = params
                    .get(1)
                    .copied()
                    .unwrap_or(self.screen.get_rows() as u64);
                self.screen.set_scroll_region(top, bottom);
            }
            b's' => self.screen.save_cursor(),
            b'u' => self.screen.restore_cursor(),
            b'h' => self.screen.handle_set_mode(params, true),
            b'l' => self.screen.handle_set_mode(params, false),
            _ => {}
        }
    }
}

trait FirstOr<T> {
    fn first_or(&self, default: T) -> T;
}

impl<T: Copy> FirstOr<T> for [T] {
    fn first_or(&self, default: T) -> T {
        self.first().copied().unwrap_or(default)
    }
}
