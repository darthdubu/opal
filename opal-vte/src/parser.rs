pub struct Parser;

impl Parser {
    pub fn new() -> Self {
        Self
    }

    pub fn parse(&mut self, _input: &[u8]) -> Vec<ParseAction> {
        vec![]
    }
}

#[derive(Debug, Clone)]
pub enum ParseAction {
    Print(char),
    Execute(u8),
    Csi(CsiAction),
    Osc(OscAction),
}

#[derive(Debug, Clone)]
pub struct CsiAction {
    pub params: Vec<u16>,
    pub intermediates: Vec<u8>,
    pub final_byte: u8,
}

#[derive(Debug, Clone)]
pub struct OscAction {
    pub params: Vec<String>,
}
