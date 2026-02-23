pub struct Parser {
    state: State,
    params: Vec<u16>,
    intermediates: Vec<u8>,
    param: u16,
    osc_string: String,
    utf8_buffer: Vec<u8>,
    utf8_remaining: usize,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum State {
    Ground,
    Escape,
    EscapeIntermediate,
    CsiEntry,
    CsiParam,
    CsiIntermediate,
    CsiIgnore,
    OscString,
    OscEscape,
    SosPmApcString,
}

#[derive(Debug, Clone)]
pub enum Action {
    Print(char),
    Execute(u8),
    CsiDispatch {
        params: Vec<u16>,
        intermediates: Vec<u8>,
        final_byte: u8,
    },
    OscDispatch(Vec<String>),
}

impl Parser {
    pub fn new() -> Self {
        Self {
            state: State::Ground,
            params: Vec::new(),
            intermediates: Vec::new(),
            param: 0,
            osc_string: String::new(),
            utf8_buffer: Vec::new(),
            utf8_remaining: 0,
        }
    }

    pub fn parse(&mut self, input: &[u8]) -> Vec<Action> {
        let mut actions = Vec::new();

        for &byte in input {
            if let Some(action) = self.advance(byte) {
                actions.push(action);
            }
        }

        actions
    }

    fn advance(&mut self, byte: u8) -> Option<Action> {
        match self.state {
            State::Ground => self.advance_ground(byte),
            State::Escape => self.advance_escape(byte),
            State::EscapeIntermediate => self.advance_escape_intermediate(byte),
            State::CsiEntry => self.advance_csi_entry(byte),
            State::CsiParam => self.advance_csi_param(byte),
            State::CsiIntermediate => self.advance_csi_intermediate(byte),
            State::CsiIgnore => self.advance_csi_ignore(byte),
            State::OscString => self.advance_osc_string(byte),
            State::OscEscape => self.advance_osc_escape(byte),
            State::SosPmApcString => self.advance_sos_pm_apc_string(byte),
        }
    }

    fn advance_ground(&mut self, byte: u8) -> Option<Action> {
        if self.utf8_remaining > 0 {
            return self.handle_utf8_continuation(byte);
        }

        match byte {
            0x1b => {
                self.state = State::Escape;
                None
            }
            0x00..=0x1f | 0x7f => Some(Action::Execute(byte)),
            0x20..=0x7e => Some(Action::Print(byte as char)),
            0x80..=0xbf => {
                self.utf8_buffer.push(byte);
                self.utf8_remaining = 0;
                self.try_decode_utf8()
            }
            0xc0..=0xdf => {
                self.utf8_buffer.push(byte);
                self.utf8_remaining = 1;
                None
            }
            0xe0..=0xef => {
                self.utf8_buffer.push(byte);
                self.utf8_remaining = 2;
                None
            }
            0xf0..=0xf7 => {
                self.utf8_buffer.push(byte);
                self.utf8_remaining = 3;
                None
            }
            _ => None,
        }
    }

    fn handle_utf8_continuation(&mut self, byte: u8) -> Option<Action> {
        if byte >= 0x80 && byte <= 0xbf {
            self.utf8_buffer.push(byte);
            self.utf8_remaining -= 1;

            if self.utf8_remaining == 0 {
                self.try_decode_utf8()
            } else {
                None
            }
        } else {
            let _ = self.utf8_buffer.drain(..);
            self.utf8_remaining = 0;
            self.advance_ground(byte)
        }
    }

    fn try_decode_utf8(&mut self) -> Option<Action> {
        if let Ok(s) = std::str::from_utf8(&self.utf8_buffer) {
            if let Some(c) = s.chars().next() {
                self.utf8_buffer.clear();
                return Some(Action::Print(c));
            }
        }
        self.utf8_buffer.clear();
        None
    }

    fn advance_escape(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x00..=0x17 | 0x19 | 0x1c..=0x1f => Some(Action::Execute(byte)),
            0x20..=0x2f => {
                self.intermediates.push(byte);
                self.state = State::EscapeIntermediate;
                None
            }
            0x30..=0x4f | 0x51..=0x57 | 0x59 | 0x5a | 0x5c | 0x60..=0x7e => {
                self.state = State::Ground;
                None
            }
            0x5b => {
                self.state = State::CsiEntry;
                self.params.clear();
                self.intermediates.clear();
                self.param = 0;
                None
            }
            0x5d => {
                self.state = State::OscString;
                self.osc_string.clear();
                None
            }
            0x50 | 0x58 | 0x5e | 0x5f => {
                self.state = State::SosPmApcString;
                None
            }
            _ => {
                self.state = State::Ground;
                None
            }
        }
    }

    fn advance_escape_intermediate(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x20..=0x2f => {
                self.intermediates.push(byte);
                None
            }
            0x30..=0x7e => {
                self.state = State::Ground;
                None
            }
            _ => {
                self.state = State::Ground;
                None
            }
        }
    }

    fn advance_csi_entry(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x00..=0x17 | 0x19 | 0x1c..=0x1f => Some(Action::Execute(byte)),
            0x30..=0x39 | 0x3b => {
                self.state = State::CsiParam;
                self.advance_csi_param(byte)
            }
            0x3a => {
                self.state = State::CsiIgnore;
                None
            }
            0x3c..=0x3f => {
                self.intermediates.push(byte);
                None
            }
            0x20..=0x2f => {
                self.intermediates.push(byte);
                self.state = State::CsiIntermediate;
                None
            }
            0x40..=0x7e => {
                self.state = State::Ground;
                Some(Action::CsiDispatch {
                    params: self.params.clone(),
                    intermediates: self.intermediates.clone(),
                    final_byte: byte,
                })
            }
            _ => {
                self.state = State::Ground;
                None
            }
        }
    }

    fn advance_csi_param(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x00..=0x17 | 0x19 | 0x1c..=0x1f => Some(Action::Execute(byte)),
            0x30..=0x39 => {
                self.param = self
                    .param
                    .saturating_mul(10)
                    .saturating_add((byte - 0x30) as u16);
                None
            }
            0x3b => {
                self.params.push(self.param);
                self.param = 0;
                None
            }
            0x3a | 0x3c..=0x3f => {
                self.state = State::CsiIgnore;
                None
            }
            0x20..=0x2f => {
                self.params.push(self.param);
                self.param = 0;
                self.intermediates.push(byte);
                self.state = State::CsiIntermediate;
                None
            }
            0x40..=0x7e => {
                self.params.push(self.param);
                self.param = 0;
                self.state = State::Ground;
                Some(Action::CsiDispatch {
                    params: self.params.clone(),
                    intermediates: self.intermediates.clone(),
                    final_byte: byte,
                })
            }
            _ => {
                self.state = State::Ground;
                None
            }
        }
    }

    fn advance_csi_intermediate(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x00..=0x17 | 0x19 | 0x1c..=0x1f => Some(Action::Execute(byte)),
            0x20..=0x2f => {
                self.intermediates.push(byte);
                None
            }
            0x40..=0x7e => {
                self.state = State::Ground;
                Some(Action::CsiDispatch {
                    params: self.params.clone(),
                    intermediates: self.intermediates.clone(),
                    final_byte: byte,
                })
            }
            _ => {
                self.state = State::Ground;
                None
            }
        }
    }

    fn advance_csi_ignore(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x00..=0x17 | 0x19 | 0x1c..=0x1f => Some(Action::Execute(byte)),
            0x40..=0x7e => {
                self.state = State::Ground;
                None
            }
            _ => None,
        }
    }

    fn advance_osc_string(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x07 => {
                self.state = State::Ground;
                self.dispatch_osc()
            }
            0x1b => {
                self.state = State::OscEscape;
                None
            }
            0x20..=0x7f => {
                self.osc_string.push(byte as char);
                None
            }
            _ => None,
        }
    }

    fn advance_osc_escape(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x5c => {
                self.state = State::Ground;
                self.dispatch_osc()
            }
            _ => {
                self.state = State::OscString;
                self.osc_string.push(0x1b as char);
                self.advance_osc_string(byte)
            }
        }
    }

    fn advance_sos_pm_apc_string(&mut self, byte: u8) -> Option<Action> {
        match byte {
            0x1b => {
                self.state = State::Escape;
                None
            }
            _ => None,
        }
    }

    fn dispatch_osc(&mut self) -> Option<Action> {
        let params: Vec<String> = self.osc_string.split(';').map(|s| s.to_string()).collect();
        Some(Action::OscDispatch(params))
    }

    pub fn reset(&mut self) {
        self.state = State::Ground;
        self.params.clear();
        self.intermediates.clear();
        self.param = 0;
        self.osc_string.clear();
        self.utf8_buffer.clear();
        self.utf8_remaining = 0;
    }
}
