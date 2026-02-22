use vte::{Params, Perform};

pub struct Terminal {
    grid: Grid,
    cursor: Cursor,
    attrs: Attributes,
    fg: Color,
    bg: Color,
    parser: vte::Parser,
}

impl Terminal {
    pub fn new() -> Self {
        Self {
            grid: Grid::new(80, 24),
            cursor: Cursor::new(),
            attrs: Attributes::default(),
            fg: Color::Default,
            bg: Color::Default,
            parser: vte::Parser::new(),
        }
    }

    pub fn process_input(&mut self, data: &[u8]) {
        // Temporarily take parser to avoid borrow checker issues
        let mut parser = std::mem::take(&mut self.parser);
        parser.advance(self, data);
        self.parser = parser;
    }

    pub fn resize(&mut self, cols: usize, rows: usize) {
        self.grid.resize(cols, rows);
    }

    pub fn get_grid(&self) -> &Grid {
        &self.grid
    }

    pub fn get_cursor(&self) -> &Cursor {
        &self.cursor
    }

    fn write_char(&mut self, c: char) {
        if let Some(cell) = self.grid.get_mut(self.cursor.col, self.cursor.row) {
            cell.ch = c;
            cell.fg = self.fg;
            cell.bg = self.bg;
            cell.attrs = self.attrs;
        }
        self.cursor.col += 1;
        if self.cursor.col >= self.grid.cols {
            self.cursor.col = 0;
            self.cursor.row += 1;
            if self.cursor.row >= self.grid.rows {
                self.cursor.row = self.grid.rows - 1;
                self.grid.scroll_up();
            }
        }
    }

    fn move_cursor_up(&mut self, n: usize) {
        self.cursor.row = self.cursor.row.saturating_sub(n);
    }

    fn move_cursor_down(&mut self, n: usize) {
        self.cursor.row = (self.cursor.row + n).min(self.grid.rows - 1);
    }

    fn move_cursor_forward(&mut self, n: usize) {
        self.cursor.col = (self.cursor.col + n).min(self.grid.cols - 1);
    }

    fn move_cursor_backward(&mut self, n: usize) {
        self.cursor.col = self.cursor.col.saturating_sub(n);
    }

    fn move_cursor_to(&mut self, row: usize, col: usize) {
        self.cursor.row = row.min(self.grid.rows - 1);
        self.cursor.col = col.min(self.grid.cols - 1);
    }

    fn clear_screen(&mut self, mode: u16) {
        match mode {
            0 => {
                for col in self.cursor.col..self.grid.cols {
                    if let Some(cell) = self.grid.get_mut(col, self.cursor.row) {
                        *cell = Cell::default();
                    }
                }
                for row in (self.cursor.row + 1)..self.grid.rows {
                    for col in 0..self.grid.cols {
                        if let Some(cell) = self.grid.get_mut(col, row) {
                            *cell = Cell::default();
                        }
                    }
                }
            }
            1 => {
                for row in 0..self.cursor.row {
                    for col in 0..self.grid.cols {
                        if let Some(cell) = self.grid.get_mut(col, row) {
                            *cell = Cell::default();
                        }
                    }
                }
                for col in 0..=self.cursor.col {
                    if let Some(cell) = self.grid.get_mut(col, self.cursor.row) {
                        *cell = Cell::default();
                    }
                }
            }
            2 | 3 => {
                self.grid.clear();
            }
            _ => {}
        }
    }

    fn clear_line(&mut self, mode: u16) {
        match mode {
            0 => {
                for col in self.cursor.col..self.grid.cols {
                    if let Some(cell) = self.grid.get_mut(col, self.cursor.row) {
                        *cell = Cell::default();
                    }
                }
            }
            1 => {
                for col in 0..=self.cursor.col {
                    if let Some(cell) = self.grid.get_mut(col, self.cursor.row) {
                        *cell = Cell::default();
                    }
                }
            }
            2 => {
                for col in 0..self.grid.cols {
                    if let Some(cell) = self.grid.get_mut(col, self.cursor.row) {
                        *cell = Cell::default();
                    }
                }
            }
            _ => {}
        }
    }

    fn set_sgr(&mut self, params: &Params) {
        let mut iter = params.iter().peekable();
        while let Some(param) = iter.next() {
            match param {
                [0] => {
                    self.attrs = Attributes::default();
                    self.fg = Color::Default;
                    self.bg = Color::Default;
                }
                [1] => self.attrs.bold = true,
                [3] => self.attrs.italic = true,
                [4] => self.attrs.underline = true,
                [9] => self.attrs.strikethrough = true,
                [22] => self.attrs.bold = false,
                [23] => self.attrs.italic = false,
                [24] => self.attrs.underline = false,
                [29] => self.attrs.strikethrough = false,
                [30..=37] => {
                    let idx = param[0] - 30;
                    self.fg = Color::Indexed(idx as u8);
                }
                [38] => {
                    // Extended foreground color - look ahead for type and value
                    if let Some(next) = iter.next() {
                        match next {
                            [2] => {
                                // Truecolor RGB
                                if let (Some(r), Some(g), Some(b)) =
                                    (iter.next(), iter.next(), iter.next())
                                {
                                    self.fg = Color::Rgb(r[0] as u8, g[0] as u8, b[0] as u8);
                                }
                            }
                            [5] => {
                                // 256 color
                                if let Some(idx) = iter.next() {
                                    self.fg = Color::Indexed(idx[0] as u8);
                                }
                            }
                            _ => {}
                        }
                    }
                }
                [40..=47] => {
                    let idx = param[0] - 40;
                    self.bg = Color::Indexed(idx as u8);
                }
                [48] => {
                    // Extended background color - look ahead for type and value
                    if let Some(next) = iter.next() {
                        match next {
                            [2] => {
                                // Truecolor RGB
                                if let (Some(r), Some(g), Some(b)) =
                                    (iter.next(), iter.next(), iter.next())
                                {
                                    self.bg = Color::Rgb(r[0] as u8, g[0] as u8, b[0] as u8);
                                }
                            }
                            [5] => {
                                // 256 color
                                if let Some(idx) = iter.next() {
                                    self.bg = Color::Indexed(idx[0] as u8);
                                }
                            }
                            _ => {}
                        }
                    }
                }
                [90..=97] => {
                    let idx = param[0] - 90 + 8;
                    self.fg = Color::Indexed(idx as u8);
                }
                [100..=107] => {
                    let idx = param[0] - 100 + 8;
                    self.bg = Color::Indexed(idx as u8);
                }
                _ => {}
            }
        }
    }
}

impl Perform for Terminal {
    fn print(&mut self, c: char) {
        self.write_char(c);
    }

    fn execute(&mut self, byte: u8) {
        match byte {
            b'\n' => {
                self.cursor.row += 1;
                if self.cursor.row >= self.grid.rows {
                    self.cursor.row = self.grid.rows - 1;
                    self.grid.scroll_up();
                }
            }
            b'\r' => self.cursor.col = 0,
            0x08 => {
                if self.cursor.col > 0 {
                    self.cursor.col -= 1;
                }
            }
            0x09 => {
                let next_tab = (self.cursor.col / 8 + 1) * 8;
                self.cursor.col = next_tab.min(self.grid.cols - 1);
            }
            _ => {}
        }
    }

    fn csi_dispatch(&mut self, params: &Params, intermediates: &[u8], ignore: bool, action: char) {
        if ignore {
            return;
        }

        let mut param_iter = params.iter();
        let first_param = param_iter.next();

        match action {
            'A' => {
                let n = first_param.map(|p| p[0]).unwrap_or(1) as usize;
                self.move_cursor_up(n);
            }
            'B' => {
                let n = first_param.map(|p| p[0]).unwrap_or(1) as usize;
                self.move_cursor_down(n);
            }
            'C' => {
                let n = first_param.map(|p| p[0]).unwrap_or(1) as usize;
                self.move_cursor_forward(n);
            }
            'D' => {
                let n = first_param.map(|p| p[0]).unwrap_or(1) as usize;
                self.move_cursor_backward(n);
            }
            'H' | 'f' => {
                let row = first_param.map(|p| p[0]).unwrap_or(1) as usize;
                let col = param_iter.next().map(|p| p[0]).unwrap_or(1) as usize;
                self.move_cursor_to(row.saturating_sub(1), col.saturating_sub(1));
            }
            'J' => {
                let mode = first_param.map(|p| p[0]).unwrap_or(0);
                self.clear_screen(mode);
            }
            'K' => {
                let mode = first_param.map(|p| p[0]).unwrap_or(0);
                self.clear_line(mode);
            }
            'm' => {
                self.set_sgr(params);
            }
            'h' => {
                if intermediates.contains(&b'?') {
                    if let Some([25]) = first_param {
                        self.cursor.visible = true;
                    }
                }
            }
            'l' => {
                if intermediates.contains(&b'?') {
                    if let Some([25]) = first_param {
                        self.cursor.visible = false;
                    }
                }
            }
            _ => {}
        }
    }

    fn osc_dispatch(&mut self, params: &[&[u8]], _bell_terminated: bool) {
        if params.is_empty() {
            return;
        }

        let osc_type = params[0];
        match osc_type {
            b"0" | b"2" => {}
            b"52" => {}
            b"133" => {}
            _ => {}
        }
    }

    fn hook(&mut self, _params: &Params, _intermediates: &[u8], _ignore: bool, _action: char) {}

    fn put(&mut self, _byte: u8) {}

    fn unhook(&mut self) {}

    fn esc_dispatch(&mut self, _intermediates: &[u8], _ignore: bool, _byte: u8) {}
}

pub struct Grid {
    cols: usize,
    rows: usize,
    cells: Vec<Cell>,
    scrollback: Vec<Vec<Cell>>,
}

impl Grid {
    pub fn new(cols: usize, rows: usize) -> Self {
        let cells = vec![Cell::default(); cols * rows];
        Self {
            cols,
            rows,
            cells,
            scrollback: Vec::with_capacity(100_000),
        }
    }

    pub fn resize(&mut self, cols: usize, rows: usize) {
        let mut new_cells = vec![Cell::default(); cols * rows];
        for row in 0..self.rows.min(rows) {
            for col in 0..self.cols.min(cols) {
                if let Some(cell) = self.get(col, row) {
                    let idx = row * cols + col;
                    if idx < new_cells.len() {
                        new_cells[idx] = cell.clone();
                    }
                }
            }
        }
        self.cols = cols;
        self.rows = rows;
        self.cells = new_cells;
    }

    pub fn get(&self, col: usize, row: usize) -> Option<&Cell> {
        if col < self.cols && row < self.rows {
            self.cells.get(row * self.cols + col)
        } else {
            None
        }
    }

    pub fn get_mut(&mut self, col: usize, row: usize) -> Option<&mut Cell> {
        if col < self.cols && row < self.rows {
            self.cells.get_mut(row * self.cols + col)
        } else {
            None
        }
    }

    pub fn clear(&mut self) {
        for cell in &mut self.cells {
            *cell = Cell::default();
        }
    }
    pub fn rows(&self) -> usize {
        self.rows
    }

    pub fn cols(&self) -> usize {
        self.cols
    }

    pub fn scroll_up(&mut self) {
        let row: Vec<Cell> = (0..self.cols)
            .filter_map(|col| self.get(col, 0).cloned())
            .collect();
        if !row.is_empty() {
            self.scrollback.push(row);
            if self.scrollback.len() > 100_000 {
                self.scrollback.remove(0);
            }
        }

        for row in 1..self.rows {
            for col in 0..self.cols {
                if let (Some(src), Some(dst)) =
                    (self.get(col, row).cloned(), self.get_mut(col, row - 1))
                {
                    *dst = src;
                }
            }
        }

        for col in 0..self.cols {
            if let Some(cell) = self.get_mut(col, self.rows - 1) {
                *cell = Cell::default();
            }
        }
    }
}

#[derive(Clone, Default)]
pub struct Cell {
    pub ch: char,
    pub fg: Color,
    pub bg: Color,
    pub attrs: Attributes,
}

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub enum Color {
    #[default]
    Default,
    Indexed(u8),
    Rgb(u8, u8, u8),
}

#[derive(Clone, Copy, Default)]
pub struct Attributes {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
}

pub struct Cursor {
    pub col: usize,
    pub row: usize,
    pub visible: bool,
}

impl Cursor {
    pub fn new() -> Self {
        Self {
            col: 0,
            row: 0,
            visible: true,
        }
    }

    pub fn move_to(&mut self, col: usize, row: usize) {
        self.col = col;
        self.row = row;
    }
}

pub trait Pty: Send + Sync {
    fn write(&mut self, data: &[u8]) -> std::io::Result<()>;
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize>;
    fn resize(&mut self, cols: u16, rows: u16) -> std::io::Result<()>;
    fn exit_status(&self) -> Option<std::process::ExitStatus>;
}
