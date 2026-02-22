use crate::cell::Flags;
use crate::color::Color;
use crate::cursor::CursorStyle;

pub trait Handler {
    fn input(&mut self, c: char);

    fn linefeed(&mut self);

    fn carriage_return(&mut self);

    fn backspace(&mut self);

    fn tab(&mut self);

    fn clear_screen(&mut self, mode: ClearMode);

    fn clear_line(&mut self, mode: ClearLineMode);

    fn set_cursor_pos(&mut self, row: usize, col: usize);

    fn move_cursor_up(&mut self, amount: usize);

    fn move_cursor_down(&mut self, amount: usize);

    fn move_cursor_left(&mut self, amount: usize);

    fn move_cursor_right(&mut self, amount: usize);

    fn set_fg(&mut self, color: Color);

    fn set_bg(&mut self, color: Color);

    fn set_flags(&mut self, flags: Flags);

    fn unset_flags(&mut self, flags: Flags);

    fn reset_attrs(&mut self);

    fn set_cursor_style(&mut self, style: CursorStyle);

    fn set_title(&mut self, title: String);

    fn set_window_title(&mut self, title: String);

    fn scroll_up(&mut self, amount: usize);

    fn scroll_down(&mut self, amount: usize);

    fn insert_lines(&mut self, amount: usize);

    fn delete_lines(&mut self, amount: usize);

    fn insert_blank_chars(&mut self, amount: usize);

    fn delete_chars(&mut self, amount: usize);

    fn set_mode(&mut self, mode: Mode);

    fn unset_mode(&mut self, mode: Mode);

    fn set_scrolling_region(&mut self, top: usize, bottom: usize);

    fn bell(&mut self);

    fn substitute(&mut self);
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ClearMode {
    Below,
    Above,
    All,
    Saved,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ClearLineMode {
    Right,
    Left,
    All,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode {
    CursorKeys,
    ColumnMode,
    LineWrap,
    BlinkingCursor,
    ShowCursor,
    ReportFocus,
    AltScreen,
    CursorBlink,
}
