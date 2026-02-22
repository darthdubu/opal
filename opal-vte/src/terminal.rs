use crate::ansi::{ClearLineMode, ClearMode, Handler, Mode};
use crate::cell::{Cell, Flags};
use crate::color::Color;
use crate::cursor::{Cursor, CursorStyle};
use crate::grid::Grid;

pub struct Terminal {
    grid: Grid,
    cursor: Cursor,
    fg: Color,
    bg: Color,
    flags: Flags,
    scroll_region: Option<(usize, usize)>,
    modes: Vec<Mode>,
    title: String,
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
            modes: Vec::new(),
            title: String::new(),
        }
    }

    pub fn grid(&self) -> &Grid {
        &self.grid
    }

    pub fn cursor(&self) -> &Cursor {
        &self.cursor
    }

    fn scroll_up_if_needed(&mut self) {
        if self.cursor.row >= self.grid.rows() {
            let scroll_region = self.scroll_region.unwrap_or((0, self.grid.rows() - 1));
            if self.cursor.row > scroll_region.1 {
                self.grid.scroll_up(1);
                self.cursor.row = scroll_region.1;
            }
        }
    }
}

impl Handler for Terminal {
    fn input(&mut self, c: char) {
        let mut cell = Cell::new(c);
        cell.fg = self.fg;
        cell.bg = self.bg;
        cell.flags = self.flags;

        self.grid.write_cell(self.cursor.row, self.cursor.col, cell);

        self.cursor.move_right(1, self.grid.cols() - 1);
        if self.cursor.col == 0 {
            self.cursor.move_down(1, self.grid.rows() - 1);
            self.scroll_up_if_needed();
        }
    }

    fn linefeed(&mut self) {
        self.cursor.move_down(1, self.grid.rows() - 1);
        self.scroll_up_if_needed();
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
                self.grid.clear_from_cursor();
            }
            ClearMode::Above => {
                self.grid.clear_to_cursor();
            }
            ClearMode::All => {
                self.grid.clear_all();
            }
            ClearMode::Saved => {
                self.grid.scrollback.clear();
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

    fn move_cursor_up(&mut self, amount: usize) {
        self.cursor.move_up(amount);
    }

    fn move_cursor_down(&mut self, amount: usize) {
        self.cursor.move_down(amount, self.grid.rows() - 1);
        self.scroll_up_if_needed();
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

    fn scroll_up(&mut self, amount: usize) {
        self.grid.scroll_up(amount);
    }

    fn scroll_down(&mut self, amount: usize) {
        self.grid.scroll_down(amount);
    }

    fn insert_lines(&mut self, amount: usize) {
        self.grid.insert_lines(self.cursor.row, amount);
    }

    fn delete_lines(&mut self, amount: usize) {
        self.grid.delete_lines(self.cursor.row, amount);
    }

    fn insert_blank_chars(&mut self, _amount: usize) {
        // Shift cells right and insert blanks
    }

    fn delete_chars(&mut self, _amount: usize) {
        // Shift cells left
    }

    fn set_mode(&mut self, mode: Mode) {
        if !self.modes.contains(&mode) {
            self.modes.push(mode);
        }
    }

    fn unset_mode(&mut self, mode: Mode) {
        self.modes.retain(|m| m != &mode);
    }

    fn set_scrolling_region(&mut self, top: usize, bottom: usize) {
        self.scroll_region = Some((top, bottom));
    }

    fn bell(&mut self) {
        // Trigger bell/alert
    }

    fn substitute(&mut self) {
        // Handle substitution character
    }
}
