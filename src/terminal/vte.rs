use std::collections::VecDeque;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ParserState {
    Ground,
    Escape,
    EscapeIntermediate,
    CsiEntry,
    CsiParam,
    CsiIntermediate,
    OscString,
    Apc,
    Sos,
    Pm,
    Ari,
    OscStart,
    OscEnd,
}

pub struct VteParser {
    state: ParserState,
    params: VecDeque<u64>,
    intermediates: Vec<u8>,
    ignore: bool,
    accumulated: Vec<u8>,
}

impl VteParser {
    pub fn new() -> Self {
        Self {
            state: ParserState::Ground,
            params: VecDeque::new(),
            intermediates: Vec::new(),
            ignore: false,
            accumulated: Vec::new(),
        }
    }

    pub fn parse(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match self.state {
            ParserState::Ground => self.parse_ground(byte, handler),
            ParserState::Escape => self.parse_escape(byte, handler),
            ParserState::EscapeIntermediate => self.parse_escape_intermediate(byte, handler),
            ParserState::CsiEntry => self.parse_csi_entry(byte, handler),
            ParserState::CsiParam => self.parse_csi_param(byte, handler),
            ParserState::CsiIntermediate => self.parse_csi_intermediate(byte, handler),
            ParserState::OscString => self.parse_osc_string(byte, handler),
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_ground(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            0x20..=0x7E => handler.print(byte as char),
            0x7F => handler.del(),
            _ => {}
        }
    }

    fn parse_escape(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x20..=0x2F => {
                self.intermediates.push(byte);
                self.state = ParserState::EscapeIntermediate;
            }
            0x30..=0x4F => {
                self.state = ParserState::Ground;
                self.handle_escape_dispatch(byte, handler);
            }
            0x50 => self.state = ParserState::Ari,
            0x5B => {
                self.params.push_back(0);
                self.state = ParserState::CsiEntry;
            }
            0x5D => self.state = ParserState::OscStart,
            0x58 | 0x5E | 0x5F => {
                self.state = ParserState::Ground;
                match byte {
                    0x58 => handler.sos(),
                    0x5E => handler.pm(),
                    0x5F => handler.apc(),
                    _ => {}
                }
            }
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_escape_intermediate(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x20..=0x2F => {
                if self.intermediates.len() < 2 {
                    self.intermediates.push(byte);
                }
            }
            0x30..=0x7E => {
                self.state = ParserState::Ground;
                self.handle_escape_dispatch(byte, handler);
            }
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_csi_entry(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x20..=0x2F => {
                if self.intermediates.len() < 2 {
                    self.intermediates.push(byte);
                }
                self.state = ParserState::CsiIntermediate;
            }
            0x30..=0x39 => {
                let param = match self.params.back_mut() {
                    Some(p) => {
                        *p = p.saturating_mul(10).saturating_add((byte - 0x30) as u64);
                        None
                    }
                    None => Some((byte - 0x30) as u64),
                };
                if let Some(p) = param {
                    self.params.push_back(p);
                }
                self.state = ParserState::CsiParam;
            }
            0x3B => {
                self.params.push_back(0);
                self.state = ParserState::CsiParam;
            }
            0x3A | 0x3C..=0x7E => {
                self.state = ParserState::Ground;
                self.handle_csi_dispatch(byte, handler);
            }
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_csi_param(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x30..=0x39 => {
                if let Some(p) = self.params.back_mut() {
                    *p = p.saturating_mul(10).saturating_add((byte - 0x30) as u64);
                }
            }
            0x3B => {
                self.params.push_back(0);
            }
            0x20..=0x2F => {
                self.state = ParserState::CsiIntermediate;
                if self.intermediates.len() < 2 {
                    self.intermediates.push(byte);
                }
            }
            0x3A | 0x3C..=0x7E => {
                self.state = ParserState::Ground;
                self.handle_csi_dispatch(byte, handler);
            }
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_csi_intermediate(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => self.handle_control(byte, handler),
            0x20..=0x2F => {
                if self.intermediates.len() < 2 {
                    self.intermediates.push(byte);
                }
            }
            0x30..=0x7E => {
                self.state = ParserState::Ground;
                self.handle_csi_dispatch(byte, handler);
            }
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => self.state = ParserState::Ground,
        }
    }

    fn parse_osc_string(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00..=0x1F => {
                if byte != 0x07 && byte != 0x1B {
                    return;
                }
            }
            0x07 => {
                self.state = ParserState::Ground;
                let params: Vec<u64> = self.params.drain(..).collect();
                let s = String::from_utf8_lossy(&self.accumulated).to_string();
                handler.osc(&params, &s);
                self.accumulated.clear();
                return;
            }
            0x1B => {
                self.state = ParserState::Escape;
                return;
            }
            _ => {}
        }
        self.accumulated.push(byte);
    }

    fn handle_control(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x00 => handler.bel(),
            0x07 => handler.bel(),
            0x08 => handler.bs(),
            0x09 => handler.ht(),
            0x0A => handler.lf(),
            0x0B => handler.vt(),
            0x0C => handler.ff(),
            0x0D => handler.cr(),
            0x1B => {
                self.state = ParserState::Escape;
                self.params.clear();
                self.intermediates.clear();
            }
            _ => {}
        }
    }

    fn handle_escape_dispatch(&mut self, byte: u8, handler: &mut impl VteHandler) {
        match byte {
            0x30 => handler.esc_0x30(),
            0x31 => handler.esc_0x31(),
            0x32 => handler.esc_0x32(),
            0x34 => handler.esc_0x34(),
            0x35 => handler.esc_0x35(),
            0x36 => handler.esc_0x36(),
            0x37 => handler.esc_0x37(),
            0x38 => handler.esc_0x38(),
            0x3C => handler.esc_0x3C(),
            0x3D => handler.esc_0x3D(),
            0x3E => handler.esc_0x3E(),
            0x3F => handler.esc_0x3F(),
            0x40 => handler.esc_0x40(),
            0x41..=0x5A | 0x5C..=0x5F => handler.esc_alpha(byte),
            _ => {}
        }
    }

    fn handle_csi_dispatch(&mut self, byte: u8, handler: &mut impl VteHandler) {
        let params: Vec<u64> = self.params.drain(..).collect();
        let intermediates: Vec<u8> = self.intermediates.drain(..).collect();

        match byte {
            0x40..=0x7E => handler.csi(byte, &params, &intermediates),
            _ => {}
        }
    }

    pub fn params_to_vec(&self) -> Vec<u64> {
        self.params.iter().cloned().collect()
    }
}

impl Default for VteParser {
    fn default() -> Self {
        Self::new()
    }
}

pub trait VteHandler: Sized {
    fn print(&mut self, c: char);
    fn del(&mut self);
    fn bs(&mut self);
    fn ht(&mut self);
    fn lf(&mut self);
    fn vt(&mut self);
    fn ff(&mut self);
    fn cr(&mut self);
    fn bel(&mut self);
    fn sos(&mut self);
    fn pm(&mut self);
    fn apc(&mut self);
    fn osc(&mut self, params: &[u64], string: &str);
    fn esc_0x30(&mut self);
    fn esc_0x31(&mut self);
    fn esc_0x32(&mut self);
    fn esc_0x34(&mut self);
    fn esc_0x35(&mut self);
    fn esc_0x36(&mut self);
    fn esc_0x37(&mut self);
    fn esc_0x38(&mut self);
    fn esc_0x3C(&mut self);
    fn esc_0x3D(&mut self);
    fn esc_0x3E(&mut self);
    fn esc_0x3F(&mut self);
    fn esc_0x40(&mut self);
    fn esc_alpha(&mut self, byte: u8);
    fn csi(&mut self, final_byte: u8, params: &[u64], intermediates: &[u8]);
}
