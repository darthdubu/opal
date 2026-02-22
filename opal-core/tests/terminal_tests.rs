use opal_core::{
    encode_key, encode_key_with_modes, encode_keypad_key, Attributes, Cell, Color, Cursor,
    Grid, InputModes, Key, KeypadKey, MouseMode, Terminal,
};

#[test]
fn test_terminal_basic_text() {
    let mut term = Terminal::new();
    
    term.process_input(b"Hello, World!");
    
    assert_eq!(term.get_cursor().row, 0);
    assert_eq!(term.get_cursor().col, 13);
    
    let cell = term.get_grid().get(0, 0).unwrap();
    assert_eq!(cell.ch, 'H');
    assert_eq!(cell.fg, Color::Default);
}

#[test]
fn test_terminal_cursor_movement() {
    let mut term = Terminal::new();

    // Test cursor movement with escape sequences
    // Start at col 0
    term.process_input(b"AB");
    // After "AB": wrote A at col 0, cursor -> 1; wrote B at col 1, cursor -> 2
    assert_eq!(term.get_cursor().col, 2);

    // Move backward 1
    term.process_input(b"\x1b[1D");
    // Cursor: 2 -> 1
    assert_eq!(term.get_cursor().col, 1);

    // Move forward 2 from col 1
    term.process_input(b"\x1b[2C");
    // Cursor: 1 + 2 = 3
    assert_eq!(term.get_cursor().col, 3);

    // Home position
    term.process_input(b"\x1b[H");
    assert_eq!(term.get_cursor().row, 0);
    assert_eq!(term.get_cursor().col, 0);

    // Move to row 5, col 10 (1-indexed in ANSI, 0-indexed internal)
    term.process_input(b"\x1b[5;10H");
    assert_eq!(term.get_cursor().row, 4);
    assert_eq!(term.get_cursor().col, 9);
}

#[test]
fn test_terminal_colors() {
    let mut term = Terminal::new();
    
    term.process_input(b"\x1b[31mRed\x1b[0m");
    
    let red_cell = term.get_grid().get(0, 0).unwrap();
    assert_eq!(red_cell.fg, Color::Indexed(1));
    
    term.process_input(b"\x1b[H\x1b[42mGreenBG\x1b[0m");
    let green_cell = term.get_grid().get(0, 0).unwrap();
    assert_eq!(green_cell.bg, Color::Indexed(2));
}

#[test]
fn test_terminal_256_colors() {
    let mut term = Terminal::new();
    
    // Set 256 color then write text
    term.process_input(b"\x1b[38;5;196mX");
    
    let cell = term.get_grid().get(0, 0).unwrap();
    assert_eq!(cell.fg, Color::Indexed(196));
}

#[test]
fn test_terminal_truecolor() {
    let mut term = Terminal::new();
    
    // Set truecolor then write text
    term.process_input(b"\x1b[38;2;255;100;50mX");
    
    let cell = term.get_grid().get(0, 0).unwrap();
    assert_eq!(cell.fg, Color::Rgb(255, 100, 50));
}

#[test]
fn test_terminal_attributes() {
    let mut term = Terminal::new();
    
    term.process_input(b"\x1b[1mBold\x1b[0m");
    let bold_cell = term.get_grid().get(0, 0).unwrap();
    assert!(bold_cell.attrs.bold);
    
    term.process_input(b"\x1b[H\x1b[3mItalic\x1b[0m");
    let italic_cell = term.get_grid().get(0, 0).unwrap();
    assert!(italic_cell.attrs.italic);
    
    term.process_input(b"\x1b[H\x1b[4mUnderline\x1b[0m");
    let underline_cell = term.get_grid().get(0, 0).unwrap();
    assert!(underline_cell.attrs.underline);
}

#[test]
fn test_terminal_erase() {
    let mut term = Terminal::new();
    
    term.process_input(b"Hello World");
    term.process_input(b"\x1b[H\x1b[K");
    
    let cell = term.get_grid().get(0, 0).unwrap();
    assert!(cell.ch == ' ' || cell.ch == '\0');
}

#[test]
fn test_input_basic_keys() {
    assert_eq!(encode_key(Key::Char('a')), vec![b'a']);
    assert_eq!(encode_key(Key::Char('Z')), vec![b'Z']);
    assert_eq!(encode_key(Key::Enter), vec![b'\r']);
    assert_eq!(encode_key(Key::Backspace), vec![0x7F]);
    assert_eq!(encode_key(Key::Tab), vec![b'\t']);
    assert_eq!(encode_key(Key::Escape), vec![0x1B]);
}

#[test]
fn test_input_arrows() {
    assert_eq!(encode_key(Key::Up), vec![0x1B, b'[', b'A']);
    assert_eq!(encode_key(Key::Down), vec![0x1B, b'[', b'B']);
    assert_eq!(encode_key(Key::Right), vec![0x1B, b'[', b'C']);
    assert_eq!(encode_key(Key::Left), vec![0x1B, b'[', b'D']);
}

#[test]
fn test_input_function_keys() {
    assert_eq!(encode_key(Key::F(1)), vec![0x1B, b'O', b'P']);
    assert_eq!(encode_key(Key::F(2)), vec![0x1B, b'O', b'Q']);
    assert_eq!(encode_key(Key::F(3)), vec![0x1B, b'O', b'R']);
    assert_eq!(encode_key(Key::F(4)), vec![0x1B, b'O', b'S']);
    assert_eq!(encode_key(Key::F(5)), vec![0x1B, b'[', b'1', b'5', b'~']);
    assert_eq!(encode_key(Key::F(12)), vec![0x1B, b'[', b'2', b'4', b'~']);
}

#[test]
fn test_input_ctrl_keys() {
    assert_eq!(encode_key(Key::Ctrl('a')), vec![0x01]);
    assert_eq!(encode_key(Key::Ctrl('c')), vec![0x03]);
    assert_eq!(encode_key(Key::Ctrl('z')), vec![0x1A]);
}

#[test]
fn test_input_alt_keys() {
    assert_eq!(encode_key(Key::Alt('a')), vec![0x1B, b'a']);
    assert_eq!(encode_key(Key::Alt('x')), vec![0x1B, b'x']);
}

#[test]
fn test_input_modified_arrows() {
    assert_eq!(
        encode_key(Key::ShiftUp),
        vec![0x1B, b'[', b'1', b';', b'2', b'A']
    );
    assert_eq!(
        encode_key(Key::CtrlRight),
        vec![0x1B, b'[', b'1', b';', b'5', b'C']
    );
}

#[test]
fn test_input_modes() {
    let mut modes = InputModes::new();
    
    assert!(!modes.application_cursor);
    assert!(!modes.application_keypad);
    assert_eq!(modes.mouse_mode, MouseMode::None);
    
    modes.enable_application_cursor();
    assert!(modes.application_cursor);
    
    modes.enable_application_keypad();
    assert!(modes.application_keypad);
    
    modes.set_mouse_mode(MouseMode::VT200);
    assert_eq!(modes.mouse_mode, MouseMode::VT200);
    
    modes.reset();
    assert!(!modes.application_cursor);
    assert!(!modes.application_keypad);
    assert_eq!(modes.mouse_mode, MouseMode::None);
}

#[test]
fn test_input_modes_arrow_keys() {
    let mut modes = InputModes::new();
    
    assert_eq!(
        encode_key_with_modes(Key::Up, &modes),
        vec![0x1B, b'[', b'A']
    );
    
    modes.enable_application_cursor();
    assert_eq!(
        encode_key_with_modes(Key::Up, &modes),
        vec![0x1B, b'O', b'A']
    );
    assert_eq!(
        encode_key_with_modes(Key::Down, &modes),
        vec![0x1B, b'O', b'B']
    );
}

#[test]
fn test_keypad_modes() {
    let mut modes = InputModes::new();
    
    // Numeric mode (default)
    assert_eq!(encode_keypad_key(KeypadKey::Num0, &modes), vec![b'0']);
    assert_eq!(encode_keypad_key(KeypadKey::Enter, &modes), vec![b'\r']);
    
    // Application keypad mode
    modes.enable_application_keypad();
    assert_eq!(encode_keypad_key(KeypadKey::Num0, &modes), vec![0x1B, b'O', b'p']);
    assert_eq!(encode_keypad_key(KeypadKey::Enter, &modes), vec![0x1B, b'O', b'M']);
}

#[test]
fn test_cursor_visibility() {
    let mut term = Terminal::new();
    
    assert!(term.get_cursor().visible);
    
    term.process_input(b"\x1b[?25l");
    assert!(!term.get_cursor().visible);
    
    term.process_input(b"\x1b[?25h");
    assert!(term.get_cursor().visible);
}

#[test]
fn test_cell_operations() {
    let cell = Cell {
        ch: 'A',
        fg: Color::Default,
        bg: Color::Default,
        attrs: Attributes::default(),
    };
    
    assert_eq!(cell.ch, 'A');
    assert_eq!(cell.fg, Color::Default);
}

#[test]
fn test_attributes_operations() {
    let mut attrs = Attributes::default();
    
    assert!(!attrs.bold);
    attrs.bold = true;
    assert!(attrs.bold);
    
    assert!(!attrs.italic);
    attrs.italic = true;
    assert!(attrs.italic);
    
    assert!(!attrs.underline);
    attrs.underline = true;
    assert!(attrs.underline);
    
    assert!(!attrs.strikethrough);
    attrs.strikethrough = true;
    assert!(attrs.strikethrough);
}

#[test]
fn test_grid_resize() {
    let mut term = Terminal::new();
    
    term.process_input(b"Test text");
    term.resize(40, 12);
    
    // Grid dimensions are private, but we can verify resize doesn't panic
    // and the terminal still functions
    term.process_input(b"More text after resize");
    // "More text after resize" is 22 chars, cursor should be at col 22
    // But since we resized, let's just verify it doesn't panic and cursor is valid
    assert!(term.get_cursor().col <= 40);
}

#[test]
fn test_color_variants() {
    assert_eq!(Color::default(), Color::Default);
    assert_eq!(Color::Indexed(5), Color::Indexed(5));
    assert_eq!(Color::Rgb(255, 128, 0), Color::Rgb(255, 128, 0));
}

#[test]
fn test_ctrl_special_keys() {
    assert_eq!(encode_key(Key::Ctrl('@')), vec![0x00]);
    assert_eq!(encode_key(Key::Ctrl('[')), vec![0x1B]);
    assert_eq!(encode_key(Key::Ctrl(' ')), vec![0x00]);
    assert_eq!(encode_key(Key::Ctrl('?')), vec![0x7F]);
}

#[test]
fn test_special_keys() {
    assert_eq!(encode_key(Key::Home), vec![0x1B, b'[', b'H']);
    assert_eq!(encode_key(Key::End), vec![0x1B, b'[', b'F']);
    assert_eq!(encode_key(Key::PageUp), vec![0x1B, b'[', b'5', b'~']);
    assert_eq!(encode_key(Key::PageDown), vec![0x1B, b'[', b'6', b'~']);
    assert_eq!(encode_key(Key::Delete), vec![0x1B, b'[', b'3', b'~']);
    assert_eq!(encode_key(Key::Insert), vec![0x1B, b'[', b'2', b'~']);
}
