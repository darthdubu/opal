pub struct Screen {
    cols: u16,
    rows: u16,
}

impl Screen {
    pub fn new(cols: u16, rows: u16) -> Self {
        Self { cols, rows }
    }

    pub fn resize(&mut self, cols: u16, rows: u16) {
        self.cols = cols;
        self.rows = rows;
    }
}
