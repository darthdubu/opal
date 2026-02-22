pub fn encode_key(key: Key) -> Vec<u8> {
    match key {
        Key::Char(c) => vec![c as u8],
        Key::Enter => vec![b'\r'],
        Key::Backspace => vec![0x7F],
        Key::Tab => vec![b'\t'],
        Key::Escape => vec![0x1B],
        Key::Up => vec![0x1B, b'[', b'A'],
        Key::Down => vec![0x1B, b'[', b'B'],
        Key::Right => vec![0x1B, b'[', b'C'],
        Key::Left => vec![0x1B, b'[', b'D'],
        Key::Home => vec![0x1B, b'[', b'H'],
        Key::End => vec![0x1B, b'[', b'F'],
        Key::PageUp => vec![0x1B, b'[', b'5', b'~'],
        Key::PageDown => vec![0x1B, b'[', b'6', b'~'],
        Key::Delete => vec![0x1B, b'[', b'3', b'~'],
        Key::Insert => vec![0x1B, b'[', b'2', b'~'],
        Key::F(n) => encode_f_key(n),
        Key::Ctrl(c) => encode_ctrl(c),
        Key::Alt(c) => vec![0x1B, c as u8],
        Key::CtrlAlt(c) => vec![0x1B, (c as u8) & 0x1F],
        Key::ShiftUp => vec![0x1B, b'[', b'1', b';', b'2', b'A'],
        Key::ShiftDown => vec![0x1B, b'[', b'1', b';', b'2', b'B'],
        Key::ShiftRight => vec![0x1B, b'[', b'1', b';', b'2', b'C'],
        Key::ShiftLeft => vec![0x1B, b'[', b'1', b';', b'2', b'D'],
        Key::CtrlUp => vec![0x1B, b'[', b'1', b';', b'5', b'A'],
        Key::CtrlDown => vec![0x1B, b'[', b'1', b';', b'5', b'B'],
        Key::CtrlRight => vec![0x1B, b'[', b'1', b';', b'5', b'C'],
        Key::CtrlLeft => vec![0x1B, b'[', b'1', b';', b'5', b'D'],
    }
}

fn encode_ctrl(c: char) -> Vec<u8> {
    match c {
        // Special handling for control sequences
        '@' => vec![0x00],  // Ctrl+@ = NUL
        '[' => vec![0x1B],  // Ctrl+[ = ESC
        '\\' => vec![0x1C], // Ctrl+\ = FS
        ']' => vec![0x1D],  // Ctrl+] = GS
        '^' => vec![0x1E],  // Ctrl+^ = RS
        '_' => vec![0x1F],  // Ctrl+_ = US
        ' ' => vec![0x00],  // Ctrl+Space = NUL
        '?' => vec![0x7F],  // Ctrl+? = DEL
        c => vec![(c.to_ascii_uppercase() as u8) & 0x1F],
    }
}

fn encode_f_key(n: u8) -> Vec<u8> {
    match n {
        1 => vec![0x1B, b'O', b'P'],
        2 => vec![0x1B, b'O', b'Q'],
        3 => vec![0x1B, b'O', b'R'],
        4 => vec![0x1B, b'O', b'S'],
        5 => vec![0x1B, b'[', b'1', b'5', b'~'],
        6 => vec![0x1B, b'[', b'1', b'7', b'~'],
        7 => vec![0x1B, b'[', b'1', b'8', b'~'],
        8 => vec![0x1B, b'[', b'1', b'9', b'~'],
        9 => vec![0x1B, b'[', b'2', b'0', b'~'],
        10 => vec![0x1B, b'[', b'2', b'1', b'~'],
        11 => vec![0x1B, b'[', b'2', b'3', b'~'],
        12 => vec![0x1B, b'[', b'2', b'4', b'~'],
        _ => vec![],
    }
}

/// Terminal input modes for compatibility with various applications
#[derive(Debug, Clone, Copy, Default)]
pub struct InputModes {
    /// Application keypad mode (DECKPAM)
    pub application_keypad: bool,
    /// Application cursor keys mode (DECCKM)
    pub application_cursor: bool,
    /// Insert mode (IRM)
    pub insert_mode: bool,
    /// Linefeed mode (LNM)
    pub linefeed_mode: bool,
    /// Auto-wrap mode (DECAWM)
    pub auto_wrap: bool,
    /// Origin mode (DECOM)
    pub origin_mode: bool,
    /// Mouse tracking mode
    pub mouse_mode: MouseMode,
    /// UTF-8 mouse mode
    pub mouse_utf8: bool,
}

/// Mouse tracking modes
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum MouseMode {
    #[default]
    None,
    /// X10 compatibility mode (only button press)
    X10,
    /// VT200 mouse tracking (button press and release)
    VT200,
    /// Button press, release, and drag tracking
    ButtonEvent,
    /// All events including motion
    AnyEvent,
}

impl InputModes {
    pub fn new() -> Self {
        Self::default()
    }

    /// Reset all modes to default state
    pub fn reset(&mut self) {
        *self = Self::default();
    }

    /// Enable application keypad mode
    pub fn enable_application_keypad(&mut self) {
        self.application_keypad = true;
    }

    /// Disable application keypad mode
    pub fn disable_application_keypad(&mut self) {
        self.application_keypad = false;
    }

    /// Enable application cursor keys mode
    pub fn enable_application_cursor(&mut self) {
        self.application_cursor = true;
    }

    /// Disable application cursor keys mode
    pub fn disable_application_cursor(&mut self) {
        self.application_cursor = false;
    }

    /// Set mouse tracking mode
    pub fn set_mouse_mode(&mut self, mode: MouseMode) {
        self.mouse_mode = mode;
    }
}

/// Encode a key with consideration for terminal modes
pub fn encode_key_with_modes(key: Key, modes: &InputModes) -> Vec<u8> {
    // Handle application cursor mode for arrow keys
    match key {
        Key::Up if modes.application_cursor => return vec![0x1B, b'O', b'A'],
        Key::Down if modes.application_cursor => return vec![0x1B, b'O', b'B'],
        Key::Right if modes.application_cursor => return vec![0x1B, b'O', b'C'],
        Key::Left if modes.application_cursor => return vec![0x1B, b'O', b'D'],
        Key::Home if modes.application_cursor => return vec![0x1B, b'O', b'H'],
        Key::End if modes.application_cursor => return vec![0x1B, b'O', b'F'],
        _ => {}
    }

    // Default encoding
    encode_key(key)
}

/// Encode a keypad key with application keypad mode consideration
pub fn encode_keypad_key(key: KeypadKey, modes: &InputModes) -> Vec<u8> {
    if modes.application_keypad {
        encode_application_keypad(key)
    } else {
        encode_numeric_keypad(key)
    }
}

fn encode_application_keypad(key: KeypadKey) -> Vec<u8> {
    use KeypadKey::*;
    match key {
        Num0 => vec![0x1B, b'O', b'p'],
        Num1 => vec![0x1B, b'O', b'q'],
        Num2 => vec![0x1B, b'O', b'r'],
        Num3 => vec![0x1B, b'O', b's'],
        Num4 => vec![0x1B, b'O', b't'],
        Num5 => vec![0x1B, b'O', b'u'],
        Num6 => vec![0x1B, b'O', b'v'],
        Num7 => vec![0x1B, b'O', b'w'],
        Num8 => vec![0x1B, b'O', b'x'],
        Num9 => vec![0x1B, b'O', b'y'],
        Decimal => vec![0x1B, b'O', b'n'],
        Enter => vec![0x1B, b'O', b'M'],
        Plus => vec![0x1B, b'O', b'l'],
        Minus => vec![0x1B, b'O', b'm'],
        Multiply => vec![0x1B, b'O', b'j'],
        Divide => vec![0x1B, b'O', b'o'],
        Equals => vec![0x1B, b'O', b'X'],
    }
}

fn encode_numeric_keypad(key: KeypadKey) -> Vec<u8> {
    use KeypadKey::*;
    match key {
        Num0 => vec![b'0'],
        Num1 => vec![b'1'],
        Num2 => vec![b'2'],
        Num3 => vec![b'3'],
        Num4 => vec![b'4'],
        Num5 => vec![b'5'],
        Num6 => vec![b'6'],
        Num7 => vec![b'7'],
        Num8 => vec![b'8'],
        Num9 => vec![b'9'],
        Decimal => vec![b'.'],
        Enter => vec![b'\r'],
        Plus => vec![b'+'],
        Minus => vec![b'-'],
        Multiply => vec![b'*'],
        Divide => vec![b'/'],
        Equals => vec![b'='],
    }
}

#[derive(Debug, Clone, Copy)]
pub enum Key {
    Char(char),
    Enter,
    Backspace,
    Tab,
    Escape,
    Up,
    Down,
    Right,
    Left,
    Home,
    End,
    PageUp,
    PageDown,
    Delete,
    Insert,
    F(u8),
    Ctrl(char),
    Alt(char),
    CtrlAlt(char),
    ShiftUp,
    ShiftDown,
    ShiftRight,
    ShiftLeft,
    CtrlUp,
    CtrlDown,
    CtrlRight,
    CtrlLeft,
}

#[derive(Debug, Clone, Copy)]
pub enum KeypadKey {
    Num0,
    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    Decimal,
    Enter,
    Plus,
    Minus,
    Multiply,
    Divide,
    Equals,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_keys() {
        assert_eq!(encode_key(Key::Char('a')), vec![b'a']);
        assert_eq!(encode_key(Key::Enter), vec![b'\r']);
        assert_eq!(encode_key(Key::Backspace), vec![0x7F]);
        assert_eq!(encode_key(Key::Tab), vec![b'\t']);
        assert_eq!(encode_key(Key::Escape), vec![0x1B]);
    }

    #[test]
    fn test_arrow_keys() {
        assert_eq!(encode_key(Key::Up), vec![0x1B, b'[', b'A']);
        assert_eq!(encode_key(Key::Down), vec![0x1B, b'[', b'B']);
        assert_eq!(encode_key(Key::Right), vec![0x1B, b'[', b'C']);
        assert_eq!(encode_key(Key::Left), vec![0x1B, b'[', b'D']);
    }

    #[test]
    fn test_ctrl_keys() {
        assert_eq!(encode_key(Key::Ctrl('c')), vec![0x03]);
        assert_eq!(encode_key(Key::Ctrl('a')), vec![0x01]);
        assert_eq!(encode_key(Key::Ctrl('z')), vec![0x1A]);
    }

    #[test]
    fn test_alt_keys() {
        assert_eq!(encode_key(Key::Alt('a')), vec![0x1B, b'a']);
        assert_eq!(encode_key(Key::Alt('x')), vec![0x1B, b'x']);
    }

    #[test]
    fn test_modified_arrows() {
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
    fn test_f_keys() {
        assert_eq!(encode_key(Key::F(1)), vec![0x1B, b'O', b'P']);
        assert_eq!(encode_key(Key::F(4)), vec![0x1B, b'O', b'S']);
        assert_eq!(encode_key(Key::F(5)), vec![0x1B, b'[', b'1', b'5', b'~']);
    }

    #[test]
    fn test_application_cursor_mode() {
        let mut modes = InputModes::new();

        // Normal mode
        assert_eq!(
            encode_key_with_modes(Key::Up, &modes),
            vec![0x1B, b'[', b'A']
        );

        // Application cursor mode
        modes.enable_application_cursor();
        assert_eq!(
            encode_key_with_modes(Key::Up, &modes),
            vec![0x1B, b'O', b'A']
        );
        assert_eq!(
            encode_key_with_modes(Key::Down, &modes),
            vec![0x1B, b'O', b'B']
        );
        assert_eq!(
            encode_key_with_modes(Key::Home, &modes),
            vec![0x1B, b'O', b'H']
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
        assert_eq!(
            encode_keypad_key(KeypadKey::Num0, &modes),
            vec![0x1B, b'O', b'p']
        );
        assert_eq!(
            encode_keypad_key(KeypadKey::Enter, &modes),
            vec![0x1B, b'O', b'M']
        );
    }

    #[test]
    fn test_input_modes() {
        let mut modes = InputModes::new();
        assert!(!modes.application_cursor);
        assert!(!modes.application_keypad);

        modes.enable_application_cursor();
        assert!(modes.application_cursor);

        modes.enable_application_keypad();
        assert!(modes.application_keypad);

        modes.reset();
        assert!(!modes.application_cursor);
        assert!(!modes.application_keypad);
    }

    #[test]
    fn test_ctrl_special() {
        assert_eq!(encode_key(Key::Ctrl('@')), vec![0x00]);
        assert_eq!(encode_key(Key::Ctrl('[')), vec![0x1B]);
        assert_eq!(encode_key(Key::Ctrl(' ')), vec![0x00]);
        assert_eq!(encode_key(Key::Ctrl('?')), vec![0x7F]);
    }
}
