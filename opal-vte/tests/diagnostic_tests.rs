#[cfg(test)]
mod diagnostic_tests {
    use opal_vte::Terminal;

    #[test]
    fn test_shell_prompt_simulation() {
        let mut term = Terminal::new(24, 80);
        let prompt = b"\x1b[01;32muser@host\x1b[00m:\x1b[01;34m~\x1b[00m$ ";
        term.process_bytes(prompt);
        let cell0 = term.grid().get_cell(0, 0).unwrap();
        assert_eq!(cell0.c, 'u');
    }

    #[test]
    fn test_ls_command_output() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"\x1b[0m\x1b[01;34m.\x1b[0m  \x1b[01;34m..\x1b[0m  \x1b[01;36mbin\x1b[0m  \x1b[00;33mfile.txt\x1b[0m\r\n");
        let cursor = term.cursor();
        assert_eq!(cursor.col, 0);
        assert_eq!(cursor.row, 1);
    }

    #[test]
    fn test_echo_command() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"echo hello\r\n");
        let cell0 = term.grid().get_cell(0, 0).unwrap();
        assert_eq!(cell0.c, 'e');
        let cursor = term.cursor();
        assert_eq!(cursor.row, 1);
        assert_eq!(cursor.col, 0);
    }

    #[test]
    fn test_cursor_movement_commands() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"A");
        term.process_bytes(b"\x1b[6;11H");
        let cursor = term.cursor();
        assert_eq!(cursor.row, 5);
        assert_eq!(cursor.col, 10);
        term.process_bytes(b"B");
        let cell = term.grid().get_cell(5, 10).unwrap();
        assert_eq!(cell.c, 'B');
    }

    #[test]
    fn test_multiple_lines() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"Line 1\r\nLine 2\r\nLine 3");
        let line1_cell = term.grid().get_cell(0, 0).unwrap();
        let line2_cell = term.grid().get_cell(1, 0).unwrap();
        let line3_cell = term.grid().get_cell(2, 0).unwrap();
        assert_eq!(line1_cell.c, 'L');
        assert_eq!(line2_cell.c, 'L');
        assert_eq!(line3_cell.c, 'L');
    }

    #[test]
    fn test_backspace() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"AB\x7f");
        let cursor = term.cursor();
        assert_eq!(cursor.col, 1);
    }

    #[test]
    fn test_color_sequences() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes(b"\x1b[31mRed\x1b[0m");
        let cell = term.grid().get_cell(0, 0).unwrap();
        match cell.fg {
            opal_vte::Color::Indexed(1) => {}
            _ => panic!("Expected red color, got {:?}", cell.fg),
        }
    }

    #[test]
    fn test_wide_characters() {
        let mut term = Terminal::new(24, 80);
        term.process_bytes("你好".as_bytes());
        let cell0 = term.grid().get_cell(0, 0).unwrap();
        assert_eq!(cell0.c, '你');
    }
}
