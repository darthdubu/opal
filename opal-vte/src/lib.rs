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
    
    #[test]
    fn test_utf8_parsing() {
        let mut parser = Parser::new();
        
        // Test 2-byte UTF-8 (é)
        let input = "é".as_bytes();
        println!("Testing UTF-8: 'é' = {:?}", input);
        let actions = parser.parse(input);
        println!("Actions: {:?}", actions);
        assert_eq!(actions.len(), 1);
        match &actions[0] {
            Action::Print(c) => assert_eq!(*c, 'é'),
            _ => panic!("Expected Print('é'), got {:?}", actions[0]),
        }
        
        // Reset and test 3-byte UTF-8 (€)
        parser.reset();
        let input = "€".as_bytes();
        println!("Testing UTF-8: '€' = {:?}", input);
        let actions = parser.parse(input);
        println!("Actions: {:?}", actions);
        assert_eq!(actions.len(), 1);
        match &actions[0] {
            Action::Print(c) => assert_eq!(*c, '€'),
            _ => panic!("Expected Print('€'), got {:?}", actions[0]),
        }
        
        // Test mixed ASCII and UTF-8
        parser.reset();
        let input = "Hello 世界!".as_bytes();
        println!("Testing mixed: 'Hello 世界!'");
        let actions = parser.parse(input);
        let chars: String = actions.iter().filter_map(|a| match a {
            Action::Print(c) => Some(*c),
            _ => None,
        }).collect();
        assert_eq!(chars, "Hello 世界!");
        println!("Parsed string: '{}'", chars);
    }
    
    #[test]
    fn test_terminal_utf8() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes("café résumé".as_bytes());
        
        let cell0 = term.grid().get_cell(0, 0).unwrap();
        let cell3 = term.grid().get_cell(0, 3).unwrap();
        
        println!("Cell 0: '{}'", cell0.c);
        println!("Cell 3: '{}'", cell3.c);
        
        assert_eq!(cell0.c, 'c');
        assert_eq!(cell3.c, 'é');
    }
}