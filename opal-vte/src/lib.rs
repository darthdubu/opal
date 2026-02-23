pub mod ansi;
pub mod cell;
pub mod color;
pub mod cursor;
pub mod grid;
pub mod handler;
pub mod parser;
pub mod performer;
pub mod terminal;

pub use ansi::Handler;
pub use cell::{Cell, Flags};
pub use color::Color;
pub use cursor::{Cursor, CursorStyle};
pub use grid::{Grid, ScrollbackBuffer};
pub use parser::{Action, Parser};
pub use terminal::Terminal;



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sgr_color_parsing() {
        let mut parser = Parser::new();
        let input = b"\x1b[31m";
        let actions = parser.parse(input);
        
        println!("Input: {:?}", input);
        println!("Actions: {:?}", actions);
        
        assert_eq!(actions.len(), 1);
        match &actions[0] {
            Action::CsiDispatch { params, intermediates, final_byte } => {
                assert_eq!(params, &vec![31u16]);
                assert!(intermediates.is_empty());
                assert_eq!(*final_byte, b'm');
            }
            _ => panic!("Expected CsiDispatch, got {:?}", actions[0]),
        }
    }
    
    #[test]
    fn test_terminal_sgr_color() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"\x1b[31mX");
        
        let cell = term.grid().get_cell(0, 0).unwrap();
        println!("Cell char: '{}'", cell.c);
        println!("Cell fg: {:?}", cell.fg);
        
        assert_eq!(cell.c, 'X');
        assert_eq!(cell.fg, Color::Indexed(1));
    }
}