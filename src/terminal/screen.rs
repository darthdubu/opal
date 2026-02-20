use super::color::CellAttributes;
use std::collections::VecDeque;

const DEFAULT_SCROLLBACK_LINES: usize = 100_000;

#[derive(Clone, Debug)]
pub struct Cell {
    pub c: char,
    pub attr: CellAttributes,
}

impl Default for Cell {
    fn default() -> Self {
        Self {
            c: ' ',
            attr: CellAttributes::default(),
        }
    }
}

impl Cell {
    pub fn new(c: char, attr: CellAttributes) -> Self {
        Self { c, attr }
    }
}

pub struct Screen {
    cols: u16,
    rows: u16,
    scrollback: VecDeque<Vec<Cell>>,
    visible: Vec<Vec<Cell>>,
    cursor_x: u16,
    cursor_y: u16,
    saved_cursor_x: u16,
    saved_cursor_y: u16,
    scroll_top: u16,
    scroll_bottom: u16,
    cursor_visible: bool,
    title: String,
    alternate_buffer: bool,
    alternate_saved: Vec<Vec<Cell>>,
}

impl Screen {
    pub fn new(cols: u16, rows: u16) -> Self {
        let mut screen = Self {
            cols,
            rows,
            scrollback: VecDeque::with_capacity(DEFAULT_SCROLLBACK_LINES),
            visible: Vec::new(),
            cursor_x: 0,
            cursor_y: 0,
            saved_cursor_x: 0,
            saved_cursor_y: 0,
            scroll_top: 0,
            scroll_bottom: rows.saturating_sub(1),
            cursor_visible: true,
            title: String::new(),
            alternate_buffer: false,
            alternate_saved: Vec::new(),
        };
        screen.clear();
        screen
    }

    pub fn resize(&mut self, cols: u16, rows: u16) {
        self.cols = cols;
        self.rows = rows;
        self.scroll_bottom = rows.saturating_sub(1);

        for row in &mut self.visible {
            row.resize(cols as usize, Cell::default());
        }
        while self.visible.len() < rows as usize {
            self.visible.push(vec![Cell::default(); cols as usize]);
        }
    }

    fn clear(&mut self) {
        let default_row = vec![Cell::default(); self.cols as usize];
        self.visible = vec![default_row.clone(); self.rows as usize];
    }

    pub fn put_char(&mut self, c: char) {
        if self.cursor_x >= self.cols {
            self.linefeed();
            self.cursor_x = 0;
        }

        if self.cursor_y < self.rows as u16 {
            self.visible[self.cursor_y as usize][self.cursor_x as usize] =
                Cell::new(c, CellAttributes::default());
            self.cursor_x += 1;
        }
    }

    pub fn delete_char(&mut self) {
        if self.cursor_x > 0 {
            self.cursor_x -= 1;
        }
        if self.cursor_y < self.rows as u16 {
            let row = &mut self.visible[self.cursor_y as usize];
            if (self.cursor_x as usize) < row.len() {
                row.remove(self.cursor_x as usize);
                row.push(Cell::default());
            }
        }
    }

    pub fn backspace(&mut self) {
        if self.cursor_x > 0 {
            self.cursor_x -= 1;
        }
    }

    pub fn tab(&mut self) {
        let tab_stop = ((self.cursor_x / 8) + 1) * 8;
        self.cursor_x = tab_stop.min(self.cols - 1);
    }

    pub fn linefeed(&mut self) {
        if self.cursor_y >= self.scroll_bottom {
            self.scroll_up(1);
        } else {
            self.cursor_y += 1;
        }
    }

    pub fn carriage_return(&mut self) {
        self.cursor_x = 0;
    }

    pub fn cursor_up(&mut self, n: u64) {
        self.cursor_y = self.cursor_y.saturating_sub(n as u16);
    }

    pub fn cursor_down(&mut self, n: u64) {
        self.cursor_y = (self.cursor_y + n as u16).min(self.rows - 1);
    }

    pub fn cursor_forward(&mut self, n: u64) {
        self.cursor_x = (self.cursor_x + n as u16).min(self.cols - 1);
    }

    pub fn cursor_back(&mut self, n: u64) {
        self.cursor_x = self.cursor_x.saturating_sub(n as u16);
    }

    pub fn cursor_next_line(&mut self, n: u64) {
        self.cursor_y = (self.cursor_y + n as u16).min(self.rows - 1);
        self.cursor_x = 0;
    }

    pub fn cursor_previous_line(&mut self, n: u64) {
        self.cursor_y = self.cursor_y.saturating_sub(n as u16);
        self.cursor_x = 0;
    }

    pub fn cursor_absolute_col(&mut self, col: u64) {
        self.cursor_x = (col.saturating_sub(1) as u16).min(self.cols - 1);
    }

    pub fn cursor_absolute_row(&mut self, row: u64) {
        self.cursor_y = (row.saturating_sub(1) as u16).min(self.rows - 1);
    }

    pub fn cursor_position(&mut self, row: u64, col: u64) {
        self.cursor_y = (row.saturating_sub(1) as u16).min(self.rows - 1);
        self.cursor_x = (col.saturating_sub(1) as u16).min(self.cols - 1);
    }

    pub fn scroll_up(&mut self, n: u64) {
        for _ in 0..n {
            if !self.visible.is_empty() {
                let line = self.visible.remove(0);
                if self.scrollback.len() >= DEFAULT_SCROLLBACK_LINES {
                    self.scrollback.pop_front();
                }
                self.scrollback.push_back(line);
            }
            self.visible.push(vec![Cell::default(); self.cols as usize]);
        }
    }

    pub fn scroll_down(&mut self, n: u64) {
        for _ in 0..n {
            self.visible.remove(self.scroll_top as usize);
            self.visible.insert(
                self.scroll_bottom as usize,
                vec![Cell::default(); self.cols as usize],
            );
        }
    }

    pub fn erase_display(&mut self, mode: u64) {
        match mode {
            0 => {
                let row = self.cursor_y as usize;
                let col = self.cursor_x as usize;
                if row < self.visible.len() {
                    for c in col..self.visible[row].len() {
                        self.visible[row][c] = Cell::default();
                    }
                }
                for r in (row + 1)..self.visible.len() {
                    self.visible[r] = vec![Cell::default(); self.cols as usize];
                }
            }
            1 => {
                for r in 0..=self.cursor_y as usize {
                    self.visible[r] = vec![Cell::default(); self.cols as usize];
                }
            }
            2 | 3 => {
                for row in &mut self.visible {
                    *row = vec![Cell::default(); self.cols as usize];
                }
                self.scrollback.clear();
            }
            _ => {}
        }
    }

    pub fn erase_line(&mut self, mode: u64) {
        let row = self.cursor_y as usize;
        if row >= self.visible.len() {
            return;
        }

        match mode {
            0 => {
                for c in (self.cursor_x as usize)..self.visible[row].len() {
                    self.visible[row][c] = Cell::default();
                }
            }
            1 => {
                for c in 0..=self.cursor_x as usize {
                    self.visible[row][c] = Cell::default();
                }
            }
            2 => {
                self.visible[row] = vec![Cell::default(); self.cols as usize];
            }
            _ => {}
        }
    }

    pub fn erase_chars(&mut self, n: u64) {
        let row = self.cursor_y as usize;
        let col = self.cursor_x as usize;
        if row >= self.visible.len() {
            return;
        }

        for i in 0..n as usize {
            let idx = col + i;
            if idx < self.visible[row].len() {
                self.visible[row][idx] = Cell::default();
            }
        }
    }

    pub fn insert_lines(&mut self, n: u64) {
        let row = self.cursor_y as usize;
        for _ in 0..n {
            self.visible.remove(row);
            self.visible.push(vec![Cell::default(); self.cols as usize]);
        }
    }

    pub fn delete_lines(&mut self, n: u64) {
        let row = self.cursor_y as usize;
        for _ in 0..n {
            self.visible.remove(row);
            self.visible.insert(
                self.scroll_bottom as usize,
                vec![Cell::default(); self.cols as usize],
            );
        }
    }

    pub fn delete_chars(&mut self, n: u64) {
        let row = self.cursor_y as usize;
        let col = self.cursor_x as usize;
        if row >= self.visible.len() {
            return;
        }

        for _ in 0..n {
            if col < self.visible[row].len() {
                self.visible[row].remove(col);
                self.visible[row].push(Cell::default());
            }
        }
    }

    pub fn set_scroll_region(&mut self, top: u64, bottom: u64) {
        self.scroll_top = (top.saturating_sub(1) as u16).min(self.rows - 1);
        self.scroll_bottom = (bottom.saturating_sub(1) as u16).min(self.rows - 1);
        self.cursor_y = self.scroll_top;
        self.cursor_x = 0;
    }

    pub fn save_cursor(&mut self) {
        self.saved_cursor_x = self.cursor_x;
        self.saved_cursor_y = self.cursor_y;
    }

    pub fn restore_cursor(&mut self) {
        self.cursor_x = self.saved_cursor_x;
        self.cursor_y = self.saved_cursor_y;
    }

    pub fn set_title(&mut self, title: &str) {
        self.title = title.to_string();
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    pub fn sgr(&mut self, params: &[u64]) {
        if params.is_empty() {
            self.sgr_one(0);
            return;
        }

        let mut i = 0;
        while i < params.len() {
            self.sgr_one(params[i]);
            i += 1;
        }
    }

    fn sgr_one(&mut self, param: u64) {
        // This is a simplified SGR handler - full implementation would track attributes
        match param {
            0 => {}
            1 => {}
            2 => {}
            3 => {}
            4 => {}
            5 => {}
            7 => {}
            8 => {}
            9 => {}
            22 => {}
            23 => {}
            24 => {}
            27 => {}
            30..=37 => {}
            38 => {}
            39 => {}
            40..=47 => {}
            48 => {}
            49 => {}
            90..=97 => {}
            100..=107 => {}
            _ => {}
        }
    }

    pub fn handle_set_mode(&mut self, params: &[u64], set: bool) {
        for &param in params {
            match param {
                1 => {}  // Application cursor keys
                7 => {}  // Auto wrap
                12 => {} // Cursor blink
                25 => {
                    self.cursor_visible = set;
                } // Cursor visible
                1000 => {} // Mouse tracking
                1002 => {} // Mouse cell tracking
                1006 => {} // Mouse SGR tracking
                2004 => {} // Bracketed paste
                _ => {}
            }
        }
    }

    pub fn get_cols(&self) -> u16 {
        self.cols
    }

    pub fn get_rows(&self) -> u16 {
        self.rows
    }

    pub fn get_cursor(&self) -> (u16, u16) {
        (self.cursor_x, self.cursor_y)
    }

    pub fn is_cursor_visible(&self) -> bool {
        self.cursor_visible
    }

    pub fn visible_cells(&self) -> &[Vec<Cell>] {
        &self.visible
    }

    pub fn scrollback_cells(&self) -> &VecDeque<Vec<Cell>> {
        &self.scrollback
    }
}
