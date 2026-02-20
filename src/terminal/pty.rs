pub struct Pty;

impl Pty {
    pub fn new() -> Self {
        Self
    }

    pub fn resize(&mut self, _cols: u16, _rows: u16) {
        unimplemented!("PTY layer")
    }
}
