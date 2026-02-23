pub use opal_vte::{Cell, Color, Cursor, CursorStyle, Flags as CellFlags, Grid, Terminal};

pub trait Pty: Send + Sync {
    fn write(&mut self, data: &[u8]) -> std::io::Result<()>;
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize>;
    fn resize(&mut self, cols: u16, rows: u16) -> std::io::Result<()>;
    fn exit_status(&self) -> Option<std::process::ExitStatus>;
}
