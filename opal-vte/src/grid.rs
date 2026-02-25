use crate::cell::Cell;
use std::collections::VecDeque;

#[derive(Clone, Debug)]
pub struct ScrollbackBuffer {
    lines: VecDeque<Vec<Cell>>,
    max_size: usize,
}

impl ScrollbackBuffer {
    pub fn new(max_size: usize) -> Self {
        Self {
            lines: VecDeque::with_capacity(max_size),
            max_size,
        }
    }

    pub fn push(&mut self, line: Vec<Cell>) {
        if self.lines.len() >= self.max_size {
            self.lines.pop_front();
        }
        self.lines.push_back(line);
    }

    pub fn get(&self, index: usize) -> Option<&[Cell]> {
        self.lines.get(index).map(|v| v.as_slice())
    }

    pub fn len(&self) -> usize {
        self.lines.len()
    }

    pub fn is_empty(&self) -> bool {
        self.lines.is_empty()
    }

    pub fn clear(&mut self) {
        self.lines.clear();
    }
}

pub struct Grid {
    rows: usize,
    cols: usize,
    cells: Vec<Cell>,
    scrollback: ScrollbackBuffer,
    cursor_row: usize,
    cursor_col: usize,
}

impl Grid {
    pub fn new(rows: usize, cols: usize, scrollback_size: usize) -> Self {
        let capacity = rows * cols;
        let cells = vec![Cell::default(); capacity];

        Self {
            rows,
            cols,
            cells,
            scrollback: ScrollbackBuffer::new(scrollback_size),
            cursor_row: 0,
            cursor_col: 0,
        }
    }

    pub fn resize(&mut self, new_rows: usize, new_cols: usize) {
        let mut new_cells = vec![Cell::default(); new_rows * new_cols];

        for row in 0..self.rows.min(new_rows) {
            for col in 0..self.cols.min(new_cols) {
                let old_idx = row * self.cols + col;
                let new_idx = row * new_cols + col;
                new_cells[new_idx] = self.cells[old_idx].clone();
            }
        }

        self.cells = new_cells;
        self.rows = new_rows;
        self.cols = new_cols;
        self.cursor_row = self.cursor_row.min(new_rows.saturating_sub(1));
        self.cursor_col = self.cursor_col.min(new_cols.saturating_sub(1));
    }

    pub fn get_cell(&self, row: usize, col: usize) -> Option<&Cell> {
        if row < self.rows && col < self.cols {
            self.cells.get(row * self.cols + col)
        } else {
            None
        }
    }

    pub fn get_cell_mut(&mut self, row: usize, col: usize) -> Option<&mut Cell> {
        if row < self.rows && col < self.cols {
            self.cells.get_mut(row * self.cols + col)
        } else {
            None
        }
    }

    pub fn write_cell(&mut self, row: usize, col: usize, cell: Cell) {
        if let Some(c) = self.get_cell_mut(row, col) {
            *c = cell;
        }
    }

    pub fn clear_line(&mut self, row: usize) {
        if row < self.rows {
            let start = row * self.cols;
            let end = start + self.cols;
            for cell in &mut self.cells[start..end] {
                cell.reset();
            }
        }
    }

    pub fn clear_line_from(&mut self, row: usize, col: usize) {
        if row < self.rows {
            let start = row * self.cols + col.min(self.cols);
            let end = (row + 1) * self.cols;
            for cell in &mut self.cells[start..end] {
                cell.reset();
            }
        }
    }

    pub fn clear_line_to(&mut self, row: usize, col: usize) {
        if row < self.rows {
            let start = row * self.cols;
            let end = start + col.min(self.cols) + 1;
            for cell in &mut self.cells[start..end] {
                cell.reset();
            }
        }
    }

    pub fn clear_all(&mut self) {
        for cell in &mut self.cells {
            cell.reset();
        }
    }

    pub fn clear_from_cursor(&mut self) {
        self.clear_from(self.cursor_row, self.cursor_col);
    }

    pub fn clear_to_cursor(&mut self) {
        self.clear_to(self.cursor_row, self.cursor_col);
    }

    pub fn clear_from(&mut self, row: usize, col: usize) {
        if self.rows == 0 || self.cols == 0 {
            return;
        }

        let row = row.min(self.rows - 1);
        let col = col.min(self.cols - 1);
        let idx = row * self.cols + col;
        for cell in &mut self.cells[idx..] {
            cell.reset();
        }
    }

    pub fn clear_to(&mut self, row: usize, col: usize) {
        if self.rows == 0 || self.cols == 0 {
            return;
        }

        let row = row.min(self.rows - 1);
        let col = col.min(self.cols - 1);
        let idx = row * self.cols + col;
        for cell in &mut self.cells[..=idx] {
            cell.reset();
        }
    }

    pub fn scroll_up(&mut self, amount: usize) {
        if self.rows == 0 {
            return;
        }
        self.scroll_up_region(0, self.rows - 1, amount);
    }

    pub fn scroll_down(&mut self, amount: usize) {
        if self.rows == 0 {
            return;
        }
        self.scroll_down_region(0, self.rows - 1, amount);
    }

    pub fn scroll_up_region(&mut self, top: usize, bottom: usize, amount: usize) {
        if self.rows == 0 || self.cols == 0 {
            return;
        }

        let top = top.min(self.rows - 1);
        let bottom = bottom.min(self.rows - 1);
        if top > bottom {
            return;
        }

        let region_rows = bottom - top + 1;
        let amount = amount.min(region_rows);
        if amount == 0 {
            return;
        }

        if top == 0 {
            for row in top..(top + amount) {
                let start = row * self.cols;
                let end = start + self.cols;
                let line: Vec<Cell> = self.cells[start..end].to_vec();
                self.scrollback.push(line);
            }
        }

        for row in (top + amount)..=bottom {
            for col in 0..self.cols {
                let src_idx = row * self.cols + col;
                let dst_idx = (row - amount) * self.cols + col;
                self.cells[dst_idx] = self.cells[src_idx].clone();
            }
        }

        for row in (bottom + 1 - amount)..=bottom {
            self.clear_line(row);
        }
    }

    pub fn scroll_down_region(&mut self, top: usize, bottom: usize, amount: usize) {
        if self.rows == 0 || self.cols == 0 {
            return;
        }

        let top = top.min(self.rows - 1);
        let bottom = bottom.min(self.rows - 1);
        if top > bottom {
            return;
        }

        let region_rows = bottom - top + 1;
        let amount = amount.min(region_rows);
        if amount == 0 {
            return;
        }

        if amount < region_rows {
            for row in (top..=(bottom - amount)).rev() {
                for col in 0..self.cols {
                    let src_idx = row * self.cols + col;
                    let dst_idx = (row + amount) * self.cols + col;
                    self.cells[dst_idx] = self.cells[src_idx].clone();
                }
            }
        }

        for row in top..(top + amount) {
            self.clear_line(row);
        }
    }

    pub fn insert_lines(&mut self, row: usize, amount: usize) {
        let amount = amount.min(self.rows - row);

        for r in (row..(self.rows - amount)).rev() {
            for col in 0..self.cols {
                let src_idx = r * self.cols + col;
                let dst_idx = (r + amount) * self.cols + col;
                self.cells[dst_idx] = self.cells[src_idx].clone();
            }
        }

        for r in row..(row + amount) {
            self.clear_line(r);
        }
    }

    pub fn delete_lines(&mut self, row: usize, amount: usize) {
        let amount = amount.min(self.rows - row);

        for r in (row + amount)..self.rows {
            for col in 0..self.cols {
                let src_idx = r * self.cols + col;
                let dst_idx = (r - amount) * self.cols + col;
                self.cells[dst_idx] = self.cells[src_idx].clone();
            }
        }

        for r in (self.rows - amount)..self.rows {
            self.clear_line(r);
        }
    }

    pub fn rows(&self) -> usize {
        self.rows
    }

    pub fn cols(&self) -> usize {
        self.cols
    }

    pub fn cursor_pos(&self) -> (usize, usize) {
        (self.cursor_row, self.cursor_col)
    }

    pub fn set_cursor_pos(&mut self, row: usize, col: usize) {
        self.cursor_row = row.min(self.rows.saturating_sub(1));
        self.cursor_col = col.min(self.cols.saturating_sub(1));
    }

    pub fn clear_scrollback(&mut self) {
        self.scrollback.clear();
    }
}
