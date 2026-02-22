pub use crate::ansi::Handler;

pub struct TerminalHandler;

impl TerminalHandler {
    pub fn new() -> Self {
        Self
    }
}

impl Default for TerminalHandler {
    fn default() -> Self {
        Self::new()
    }
}
