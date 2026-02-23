use crate::ansi::{ClearLineMode, ClearMode, Handler, Mode};
use crate::cell::Flags;
use crate::color::Color;
use crate::parser::Action;

/// Bridges Parser output (Actions) to Terminal input (Handler trait)
///
/// The Performer takes the Actions produced by the Parser and dispatches
/// them to the appropriate Handler methods, completing the terminal
/// emulation pipeline.
pub struct Performer;

impl Performer {
    pub fn new() -> Self {
        Self
    }

    /// Perform a single action on the given handler
    pub fn perform<H: Handler>(&self, handler: &mut H, action: Action) {
        match action {
            Action::Print(c) => handler.input(c),
            Action::Execute(byte) => self.execute_control(handler, byte),
            Action::CsiDispatch {
                params,
                intermediates,
                final_byte,
            } => self.dispatch_csi(handler, &params, &intermediates, final_byte),
            Action::OscDispatch(params) => self.dispatch_osc(handler, &params),
        }
    }

    /// Execute C0 control codes (0x00-0x1F)
    fn execute_control<H: Handler>(&self, handler: &mut H, byte: u8) {
        match byte {
            0x07 => handler.bell(),
            0x08 => handler.backspace(),
            0x09 => handler.tab(),
            0x0A => handler.linefeed(),
            0x0D => handler.carriage_return(),
            _ => {} // Other control codes not yet implemented
        }
    }

    /// Dispatch CSI (Control Sequence Introducer) commands
    ///
    /// CSI sequences have the format: ESC [ <params> <intermediates> <final>
    /// where final byte is in the range 0x40-0x7E (@ A-Z [ \ ] ^ _ ` a-z { | } ~)
    fn dispatch_csi<H: Handler>(
        &self,
        handler: &mut H,
        params: &[u16],
        intermediates: &[u8],
        final_byte: u8,
    ) {
        // Helper to get first parameter with default
        let param = |default: u16| params.first().copied().unwrap_or(default);

        match final_byte {
            // Cursor Positioning
            b'A' => handler.move_cursor_up(param(1) as usize),
            b'B' => handler.move_cursor_down(param(1) as usize),
            b'C' => handler.move_cursor_right(param(1) as usize),
            b'D' => handler.move_cursor_left(param(1) as usize),
            b'E' => {
                // CNL - Cursor Next Line
                handler.move_cursor_down(param(1) as usize);
                handler.carriage_return();
            }
            b'F' => {
                // CPL - Cursor Previous Line
                handler.move_cursor_up(param(1) as usize);
                handler.carriage_return();
            }
            b'G' => {
                // CHA - Cursor Horizontal Absolute
                let col = param(1).saturating_sub(1) as usize;
                handler.set_cursor_pos(0, col);
            }
            b'H' | b'f' => {
                // CUP - Cursor Position or HVP - Horizontal and Vertical Position
                let row = param(1).saturating_sub(1) as usize;
                let col = params.get(1).copied().unwrap_or(1).saturating_sub(1) as usize;
                handler.set_cursor_pos(row, col);
            }

            // Erase Functions
            b'J' => {
                let mode = match param(0) {
                    0 => ClearMode::Below,
                    1 => ClearMode::Above,
                    2 => ClearMode::All,
                    3 => ClearMode::Saved,
                    _ => ClearMode::Below,
                };
                handler.clear_screen(mode);
            }
            b'K' => {
                let mode = match param(0) {
                    0 => ClearLineMode::Right,
                    1 => ClearLineMode::Left,
                    2 => ClearLineMode::All,
                    _ => ClearLineMode::Right,
                };
                handler.clear_line(mode);
            }

            // Line Manipulation
            b'L' => handler.insert_lines(param(1) as usize),
            b'M' => handler.delete_lines(param(1) as usize),
            b'P' => handler.delete_chars(param(1) as usize),
            b'@' => handler.insert_blank_chars(param(1) as usize),

            // Scrolling
            b'S' => handler.scroll_up(param(1) as usize),
            b'T' => handler.scroll_down(param(1) as usize),

            // Select Graphic Rendition (SGR)
            b'm' => self.dispatch_sgr(handler, params),

            // Mode Settings (DECSET/DECRST)
            b'h' => {
                if intermediates.contains(&b'?') {
                    // DECSET - DEC Private Mode Set
                    self.dispatch_decset(handler, params);
                } else {
                    // SM - Set Mode
                    for &p in params {
                        if let Some(mode) = mode_from_u16(p) {
                            handler.set_mode(mode);
                        }
                    }
                }
            }
            b'l' => {
                if intermediates.contains(&b'?') {
                    // DECRST - DEC Private Mode Reset
                    self.dispatch_decrst(handler, params);
                } else {
                    // RM - Reset Mode
                    for &p in params {
                        if let Some(mode) = mode_from_u16(p) {
                            handler.unset_mode(mode);
                        }
                    }
                }
            }

            // Set Scrolling Region
            b'r' => {
                let top = param(1).saturating_sub(1) as usize;
                let bottom = params.get(1).copied().unwrap_or(1).saturating_sub(1) as usize;
                handler.set_scrolling_region(top, bottom);
            }

            // Cursor Style
            b' ' => {
                if intermediates.contains(&b'>') {
                    // DA2 - Secondary Device Attributes
                    // Ignored for now
                }
            }

            _ => {} // Unknown CSI sequence
        }
    }

    /// Dispatch SGR (Select Graphic Rendition) parameters
    fn dispatch_sgr<H: Handler>(&self, handler: &mut H, params: &[u16]) {
        if params.is_empty() {
            handler.reset_attrs();
            return;
        }

        let mut iter = params.iter();
        while let Some(&param) = iter.next() {
            match param {
                0 => handler.reset_attrs(),
                1 => handler.set_flags(Flags::BOLD),
                3 => handler.set_flags(Flags::ITALIC),
                4 => handler.set_flags(Flags::UNDERLINE),
                7 => handler.set_flags(Flags::INVERSE),
                8 => handler.set_flags(Flags::HIDDEN),
                9 => handler.set_flags(Flags::STRIKETHROUGH),
                22 => handler.unset_flags(Flags::BOLD),
                23 => handler.unset_flags(Flags::ITALIC),
                24 => handler.unset_flags(Flags::UNDERLINE),
                27 => handler.unset_flags(Flags::INVERSE),
                28 => handler.unset_flags(Flags::HIDDEN),
                29 => handler.unset_flags(Flags::STRIKETHROUGH),

                // Foreground colors (30-37)
                30..=37 => {
                    let color = Color::from_ansi_index((param - 30) as u8);
                    handler.set_fg(color);
                }
                // Foreground bright colors (90-97)
                90..=97 => {
                    let color = Color::from_ansi_index((param - 90 + 8) as u8);
                    handler.set_fg(color);
                }
                // Extended foreground color
                38 => {
                    if let Some(&next) = iter.next() {
                        match next {
                            2 => {
                                // True color RGB
                                if let (Some(&r), Some(&g), Some(&b)) =
                                    (iter.next(), iter.next(), iter.next())
                                {
                                    handler.set_fg(Color::Rgb(r as u8, g as u8, b as u8));
                                }
                            }
                            5 => {
                                // 256 color
                                if let Some(&idx) = iter.next() {
                                    handler.set_fg(Color::from_ansi_index(idx as u8));
                                }
                            }
                            _ => {}
                        }
                    }
                }

                // Background colors (40-47)
                40..=47 => {
                    let color = Color::from_ansi_index((param - 40) as u8);
                    handler.set_bg(color);
                }
                // Background bright colors (100-107)
                100..=107 => {
                    let color = Color::from_ansi_index((param - 100 + 8) as u8);
                    handler.set_bg(color);
                }
                // Extended background color
                48 => {
                    if let Some(&next) = iter.next() {
                        match next {
                            2 => {
                                // True color RGB
                                if let (Some(&r), Some(&g), Some(&b)) =
                                    (iter.next(), iter.next(), iter.next())
                                {
                                    handler.set_bg(Color::Rgb(r as u8, g as u8, b as u8));
                                }
                            }
                            5 => {
                                // 256 color
                                if let Some(&idx) = iter.next() {
                                    handler.set_bg(Color::from_ansi_index(idx as u8));
                                }
                            }
                            _ => {}
                        }
                    }
                }
                _ => {} // Unknown SGR parameter
            }
        }
    }

    /// Dispatch DECSET (DEC Private Mode Set)
    fn dispatch_decset<H: Handler>(&self, handler: &mut H, params: &[u16]) {
        for &param in params {
            match param {
                25 => handler.set_mode(Mode::ShowCursor), // Show cursor
                1049 => {
                    // Use Alternate Screen Buffer
                    handler.set_mode(Mode::AltScreen);
                }
                2004 => handler.set_mode(Mode::BracketedPaste),
                _ => {}
            }
        }
    }

    /// Dispatch DECRST (DEC Private Mode Reset)
    fn dispatch_decrst<H: Handler>(&self, handler: &mut H, params: &[u16]) {
        for &param in params {
            match param {
                25 => handler.unset_mode(Mode::ShowCursor), // Hide cursor
                1049 => handler.unset_mode(Mode::AltScreen),
                2004 => handler.unset_mode(Mode::BracketedPaste),
                _ => {}
            }
        }
    }

    /// Dispatch OSC (Operating System Command) sequences
    fn dispatch_osc<H: Handler>(&self, handler: &mut H, params: &[String]) {
        if params.is_empty() {
            return;
        }

        let osc_type = params[0].parse::<u16>().ok();

        match osc_type {
            Some(0) | Some(2) => {
                // Set window title (both icon and title)
                if let Some(title) = params.get(1) {
                    handler.set_window_title(title.clone());
                }
            }
            Some(1) => {
                // Set icon name
                if let Some(title) = params.get(1) {
                    handler.set_title(title.clone());
                }
            }
            _ => {} // Unknown or unimplemented OSC sequence
        }
    }
}

impl Default for Performer {
    fn default() -> Self {
        Self::new()
    }
}

/// Convert numeric mode code to Mode enum
fn mode_from_u16(code: u16) -> Option<Mode> {
    match code {
        // Standard modes
        4 => Some(Mode::InsertMode),
        20 => Some(Mode::LineFeedNewLineMode),
        _ => None,
    }
}
