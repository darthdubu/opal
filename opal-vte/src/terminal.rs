use crate::ansi::{ClearLineMode, ClearMode, Handler, Mode};
use crate::cell::{Cell, Flags};
use crate::color::Color;
use crate::cursor::{Cursor, CursorStyle};
use crate::grid::Grid;
use crate::parser::Parser;
use crate::performer::Performer;

pub struct Terminal {
    grid: Grid,
    cursor: Cursor,
    fg: Color,
    bg: Color,
    flags: Flags,
    scroll_region: Option<(usize, usize)>,
    modes: Vec<Mode>,
    title: String,
    current_directory: String,
    outbound: Vec<u8>,
    parser: Parser,
    performer: Performer,
}

impl Terminal {
    pub fn new(rows: usize, cols: usize) -> Self {
        Self {
            grid: Grid::new(rows, cols, 10000),
            cursor: Cursor::new(0, 0),
            fg: Color::default(),
            bg: Color::default(),
            flags: Flags::empty(),
            scroll_region: None,
            modes: vec![Mode::LineWrap, Mode::ShowCursor],
            title: String::new(),
            current_directory: String::new(),
            outbound: Vec::new(),
            parser: Parser::new(),
            performer: Performer::new(),
        }
    }

    pub fn grid(&self) -> &Grid {
        &self.grid
    }

    pub fn cursor(&self) -> &Cursor {
        &self.cursor
    }

    pub fn current_directory(&self) -> &str {
        &self.current_directory
    }

    pub fn process_bytes(&mut self, data: &[u8]) {
        let actions = {
            let parser = &mut self.parser;
            parser.parse(data)
        };
        let performer = std::mem::take(&mut self.performer);
        for action in actions {
            performer.perform(self, action);
        }
        self.performer = performer;
    }

    pub fn take_outbound(&mut self) -> Vec<u8> {
        std::mem::take(&mut self.outbound)
    }

    pub fn resize(&mut self, rows: usize, cols: usize) {
        if rows == 0 || cols == 0 {
            return;
        }

        self.grid.resize(rows, cols);
        self.cursor.row = self.cursor.row.min(rows - 1);
        self.cursor.col = self.cursor.col.min(cols - 1);

        if let Some((top, bottom)) = self.scroll_region {
            let new_bottom = bottom.min(rows - 1);
            if top >= rows || top >= new_bottom {
                self.scroll_region = None;
            } else {
                self.scroll_region = Some((top, new_bottom));
            }
        }
    }

    fn scroll_region_bounds(&self) -> (usize, usize) {
        if self.grid.rows() == 0 {
            return (0, 0);
        }

        self.scroll_region.unwrap_or((0, self.grid.rows() - 1))
    }

    fn linefeed_in_region(&mut self) {
        let (top, bottom) = self.scroll_region_bounds();

        if self.cursor.row < top {
            self.cursor.row = top;
        }

        if self.cursor.row >= bottom {
            self.grid.scroll_up_region(top, bottom, 1);
            self.cursor.row = bottom;
        } else {
            self.cursor.row += 1;
        }
    }

    fn line_wrap_enabled(&self) -> bool {
        self.modes.contains(&Mode::LineWrap)
    }

    fn in_insert_mode(&self) -> bool {
        self.modes.contains(&Mode::InsertMode)
    }

    fn line_feed_new_line_mode(&self) -> bool {
        self.modes.contains(&Mode::LineFeedNewLineMode)
    }
}

impl Handler for Terminal {
    fn input(&mut self, c: char) {
        if self.in_insert_mode() {
            self.insert_blank_chars(1);
        }

        let mut cell = Cell::new(c);
        cell.fg = self.fg;
        cell.bg = self.bg;
        cell.flags = self.flags;

        self.grid.write_cell(self.cursor.row, self.cursor.col, cell);

        let max_col = self.grid.cols().saturating_sub(1);
        if self.cursor.col >= max_col {
            if self.line_wrap_enabled() {
                self.cursor.col = 0;
                self.linefeed_in_region();
            } else {
                self.cursor.col = max_col;
            }
        } else {
            self.cursor.col += 1;
        }
    }

    fn linefeed(&mut self) {
        self.linefeed_in_region();
        if self.line_feed_new_line_mode() {
            self.cursor.col = 0;
        }
    }

    fn carriage_return(&mut self) {
        self.cursor.col = 0;
    }

    fn backspace(&mut self) {
        self.cursor.move_left(1);
    }

    fn tab(&mut self) {
        let next_tab = (self.cursor.col / 8 + 1) * 8;
        self.cursor.col = next_tab.min(self.grid.cols() - 1);
    }

    fn clear_screen(&mut self, mode: ClearMode) {
        match mode {
            ClearMode::Below => {
                self.grid.clear_from(self.cursor.row, self.cursor.col);
            }
            ClearMode::Above => {
                self.grid.clear_to(self.cursor.row, self.cursor.col);
            }
            ClearMode::All => {
                self.grid.clear_all();
            }
            ClearMode::Saved => {
                self.grid.clear_scrollback();
            }
        }
    }

    fn clear_line(&mut self, mode: ClearLineMode) {
        match mode {
            ClearLineMode::Right => {
                self.grid.clear_line_from(self.cursor.row, self.cursor.col);
            }
            ClearLineMode::Left => {
                self.grid.clear_line_to(self.cursor.row, self.cursor.col);
            }
            ClearLineMode::All => {
                self.grid.clear_line(self.cursor.row);
            }
        }
    }

    fn set_cursor_pos(&mut self, row: usize, col: usize) {
        self.cursor.row = row.min(self.grid.rows() - 1);
        self.cursor.col = col.min(self.grid.cols() - 1);
    }

    fn set_cursor_row(&mut self, row: usize) {
        self.cursor.row = row.min(self.grid.rows() - 1);
    }

    fn set_cursor_col(&mut self, col: usize) {
        self.cursor.col = col.min(self.grid.cols() - 1);
    }

    fn move_cursor_up(&mut self, amount: usize) {
        self.cursor.move_up(amount);
    }

    fn move_cursor_down(&mut self, amount: usize) {
        self.cursor.move_down(amount, self.grid.rows() - 1);
    }

    fn move_cursor_left(&mut self, amount: usize) {
        self.cursor.move_left(amount);
    }

    fn move_cursor_right(&mut self, amount: usize) {
        self.cursor.move_right(amount, self.grid.cols() - 1);
    }

    fn set_fg(&mut self, color: Color) {
        self.fg = color;
    }

    fn set_bg(&mut self, color: Color) {
        self.bg = color;
    }

    fn set_flags(&mut self, flags: Flags) {
        self.flags.insert(flags);
    }

    fn unset_flags(&mut self, flags: Flags) {
        self.flags.remove(flags);
    }

    fn reset_attrs(&mut self) {
        self.fg = Color::default();
        self.bg = Color::default();
        self.flags = Flags::empty();
    }

    fn set_cursor_style(&mut self, style: CursorStyle) {
        self.cursor.style = style;
    }

    fn set_title(&mut self, title: String) {
        self.title = title;
    }

    fn set_window_title(&mut self, title: String) {
        self.title = title;
    }

    fn set_current_directory(&mut self, path: String) {
        self.current_directory = path;
    }

    fn scroll_up(&mut self, amount: usize) {
        let (top, bottom) = self.scroll_region_bounds();
        self.grid.scroll_up_region(top, bottom, amount);
    }

    fn scroll_down(&mut self, amount: usize) {
        let (top, bottom) = self.scroll_region_bounds();
        self.grid.scroll_down_region(top, bottom, amount);
    }

    fn insert_lines(&mut self, amount: usize) {
        self.grid.insert_lines(self.cursor.row, amount);
    }

    fn delete_lines(&mut self, amount: usize) {
        self.grid.delete_lines(self.cursor.row, amount);
    }

    fn insert_blank_chars(&mut self, amount: usize) {
        let amount = amount.min(self.grid.cols() - self.cursor.col);
        let row = self.cursor.row;

        for _ in 0..amount {
            if let Some(line_end) = self.grid.get_cell(row, self.grid.cols() - 1) {
                if line_end.c != ' ' {
                    let _ = self.grid.get_cell(row, self.grid.cols() - 1);
                }
            }
        }

        for col in (self.cursor.col..self.grid.cols()).rev() {
            let src_col = col.saturating_sub(amount);
            if let (Some(src), Some(dst)) = (
                self.grid.get_cell(row, src_col).cloned(),
                self.grid.get_cell_mut(row, col),
            ) {
                *dst = src;
            }
        }

        for col in self.cursor.col..(self.cursor.col + amount).min(self.grid.cols()) {
            if let Some(cell) = self.grid.get_cell_mut(row, col) {
                cell.reset();
            }
        }
    }

    fn delete_chars(&mut self, amount: usize) {
        let amount = amount.min(self.grid.cols() - self.cursor.col);
        let row = self.cursor.row;

        for col in self.cursor.col..(self.grid.cols() - amount) {
            if let Some(src) = self.grid.get_cell(row, col + amount).cloned() {
                if let Some(dst) = self.grid.get_cell_mut(row, col) {
                    *dst = src;
                }
            }
        }

        for col in (self.grid.cols() - amount)..self.grid.cols() {
            if let Some(cell) = self.grid.get_cell_mut(row, col) {
                cell.reset();
            }
        }
    }

    fn set_mode(&mut self, mode: Mode) {
        if !self.modes.contains(&mode) {
            self.modes.push(mode);
        }
        // Handle mode-specific side effects
        if mode == Mode::ShowCursor {
            self.cursor.visible = true;
        }
    }

    fn unset_mode(&mut self, mode: Mode) {
        self.modes.retain(|m| m != &mode);
        // Handle mode-specific side effects
        if mode == Mode::ShowCursor {
            self.cursor.visible = false;
        }
    }

    fn set_scrolling_region(&mut self, top: usize, bottom: usize) {
        if self.grid.rows() == 0 {
            self.scroll_region = None;
            return;
        }

        let max_row = self.grid.rows() - 1;
        let top = top.min(max_row);
        let bottom = if bottom == usize::MAX {
            max_row
        } else {
            bottom.min(max_row)
        };

        if top >= bottom {
            self.scroll_region = None;
        } else {
            self.scroll_region = Some((top, bottom));
        }

        self.cursor.row = 0;
        self.cursor.col = 0;
    }

    fn device_status(&mut self, status: u16) {
        match status {
            // "OK" status report
            5 => self.outbound.extend_from_slice(b"\x1b[0n"),
            // Cursor Position Report (CPR): ESC [ row ; col R (1-based)
            6 => {
                let row = self.cursor.row + 1;
                let col = self.cursor.col + 1;
                self.outbound
                    .extend_from_slice(format!("\x1b[{};{}R", row, col).as_bytes());
            }
            _ => {}
        }
    }

    fn bell(&mut self) {
        // TODO: Implement bell/alert notification
    }

    fn substitute(&mut self) {
        // Handle substitution character - typically display replacement char
        self.input('\u{FFFD}');
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cell_char(term: &Terminal, row: usize, col: usize) -> char {
        term.grid().get_cell(row, col).map(|cell| cell.c).unwrap()
    }

    #[test]
    fn wraps_to_next_line_when_enabled() {
        let mut term = Terminal::new(2, 3);
        term.process_bytes(b"abcd");

        assert_eq!(cell_char(&term, 0, 0), 'a');
        assert_eq!(cell_char(&term, 0, 1), 'b');
        assert_eq!(cell_char(&term, 0, 2), 'c');
        assert_eq!(cell_char(&term, 1, 0), 'd');
        assert_eq!(term.cursor().row, 1);
        assert_eq!(term.cursor().col, 1);
    }

    #[test]
    fn linefeed_scrolls_at_bottom() {
        let mut term = Terminal::new(3, 5);
        term.process_bytes(b"A\r\nB\r\nC\r\nD");

        assert_eq!(cell_char(&term, 0, 0), 'B');
        assert_eq!(cell_char(&term, 1, 0), 'C');
        assert_eq!(cell_char(&term, 2, 0), 'D');
        assert_eq!(term.cursor().row, 2);
        assert_eq!(term.cursor().col, 1);
    }

    #[test]
    fn cha_keeps_current_row() {
        let mut term = Terminal::new(6, 10);
        term.process_bytes(b"\x1b[3;5H\x1b[1G");

        assert_eq!(term.cursor().row, 2);
        assert_eq!(term.cursor().col, 0);
    }

    #[test]
    fn clear_below_respects_terminal_cursor() {
        let mut term = Terminal::new(4, 6);
        term.process_bytes(b"abc\r\ndef");
        term.process_bytes(b"\x1b[2;2H\x1b[J");

        assert_eq!(cell_char(&term, 0, 0), 'a');
        assert_eq!(cell_char(&term, 0, 2), 'c');
        assert_eq!(cell_char(&term, 1, 0), 'd');
        assert_eq!(cell_char(&term, 1, 1), ' ');
        assert_eq!(cell_char(&term, 1, 2), ' ');
    }

    #[test]
    fn set_scrolling_region_without_params_uses_full_screen() {
        let mut term = Terminal::new(3, 5);
        term.process_bytes(b"\x1b[rA\r\nB\r\nC\r\nD");

        assert_eq!(cell_char(&term, 0, 0), 'B');
        assert_eq!(cell_char(&term, 1, 0), 'C');
        assert_eq!(cell_char(&term, 2, 0), 'D');
    }

    #[test]
    fn csi_6n_reports_cursor_position() {
        let mut term = Terminal::new(4, 10);
        term.process_bytes(b"\x1b[3;5H\x1b[6n");

        assert_eq!(term.take_outbound(), b"\x1b[3;5R");
    }

    #[test]
    fn csi_5n_reports_ok_status() {
        let mut term = Terminal::new(2, 2);
        term.process_bytes(b"\x1b[5n");

        assert_eq!(term.take_outbound(), b"\x1b[0n");
    }

    #[test]
    fn osc_7_updates_current_directory() {
        let mut term = Terminal::new(2, 2);
        term.process_bytes(b"\x1b]7;file:///Users/june/projects/Opal\x07");
        assert_eq!(term.current_directory(), "/Users/june/projects/Opal");
    }
}
