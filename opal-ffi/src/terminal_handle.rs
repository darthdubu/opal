use crate::{TerminalCell, TerminalColor, TerminalHandle};
use opal_core::Terminal;
use std::sync::{Arc, Mutex};

#[uniffi::export]
impl TerminalHandle {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            terminal: Mutex::new(Terminal::new(24, 80)),
        })
    }

    pub fn process_input(self: Arc<Self>, data: &[u8]) {
        let mut term = self.terminal.lock().unwrap();
        term.process_bytes(data);
    }

    pub fn process_input_with_responses(self: Arc<Self>, data: &[u8]) -> Vec<u8> {
        let mut term = self.terminal.lock().unwrap();
        term.process_bytes(data);
        term.take_outbound()
    }

    pub fn rows(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.grid().rows() as u32
    }

    pub fn cols(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.grid().cols() as u32
    }

    pub fn cursor_row(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.cursor().row as u32
    }

    pub fn cursor_col(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.cursor().col as u32
    }

    pub fn cursor_visible(&self) -> bool {
        let term = self.terminal.lock().unwrap();
        term.cursor().visible
    }

    pub fn current_directory(&self) -> String {
        let term = self.terminal.lock().unwrap();
        term.current_directory().to_string()
    }

    pub fn resize(&self, cols: u32, rows: u32) {
        let mut term = self.terminal.lock().unwrap();
        term.resize(rows as usize, cols as usize);
    }

    pub fn cell_at(&self, col: u32, row: u32) -> Option<TerminalCell> {
        let term = self.terminal.lock().unwrap();
        term.grid()
            .get_cell(row as usize, col as usize)
            .map(|cell| {
                let content = if cell.c == '\0' {
                    " ".to_string()
                } else {
                    cell.c.to_string()
                };

                TerminalCell {
                    content,
                    foreground: TerminalColor::from(&cell.fg),
                    background: TerminalColor::from(&cell.bg),
                    bold: cell.flags.contains(opal_core::CellFlags::BOLD),
                    italic: cell.flags.contains(opal_core::CellFlags::ITALIC),
                    underline: cell.flags.contains(opal_core::CellFlags::UNDERLINE),
                    strikethrough: cell.flags.contains(opal_core::CellFlags::STRIKETHROUGH),
                }
            })
    }

    pub fn version(&self) -> String {
        env!("CARGO_PKG_VERSION").to_string()
    }
}
