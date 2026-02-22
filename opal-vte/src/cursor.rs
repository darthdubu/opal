#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum CursorStyle {
    #[default]
    Block,
    Underline,
    Line,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub struct Cursor {
    pub row: usize,
    pub col: usize,
    pub style: CursorStyle,
    pub visible: bool,
}

impl Cursor {
    pub fn new(row: usize, col: usize) -> Self {
        Self {
            row,
            col,
            style: CursorStyle::default(),
            visible: true,
        }
    }

    pub fn move_to(&mut self, row: usize, col: usize) {
        self.row = row;
        self.col = col;
    }

    pub fn move_up(&mut self, amount: usize) {
        self.row = self.row.saturating_sub(amount);
    }

    pub fn move_down(&mut self, amount: usize, max_row: usize) {
        self.row = (self.row + amount).min(max_row);
    }

    pub fn move_left(&mut self, amount: usize) {
        self.col = self.col.saturating_sub(amount);
    }

    pub fn move_right(&mut self, amount: usize, max_col: usize) {
        self.col = (self.col + amount).min(max_col);
    }

    pub fn set_style(&mut self, style: CursorStyle) {
        self.style = style;
    }

    pub fn hide(&mut self) {
        self.visible = false;
    }

    pub fn show(&mut self) {
        self.visible = true;
    }
}
