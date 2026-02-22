uniffi::setup_scaffolding!();

use opal_core::pty::PtySession as CorePtySession;
use opal_core::{Color as CoreColor, Terminal};
use std::sync::{Arc, Mutex};

// Re-export types for internal use
pub use opal_core;
pub use opal_renderer;

mod renderer_bridge;
pub use renderer_bridge::*;

/// Terminal cell representation for FFI
#[derive(uniffi::Record, Clone)]
pub struct TerminalCell {
    pub content: String,
    pub foreground: TerminalColor,
    pub background: TerminalColor,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
}

/// Terminal color enumeration
#[derive(uniffi::Enum, Clone)]
pub enum TerminalColor {
    Default,
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    BrightBlack,
    BrightRed,
    BrightGreen,
    BrightYellow,
    BrightBlue,
    BrightMagenta,
    BrightCyan,
    BrightWhite,
    Indexed(u8),
    Rgb(u8, u8, u8),
}

impl From<&CoreColor> for TerminalColor {
    fn from(color: &CoreColor) -> Self {
        match color {
            CoreColor::Default => TerminalColor::Default,
            CoreColor::Indexed(idx) => match *idx {
                0 => TerminalColor::Black,
                1 => TerminalColor::Red,
                2 => TerminalColor::Green,
                3 => TerminalColor::Yellow,
                4 => TerminalColor::Blue,
                5 => TerminalColor::Magenta,
                6 => TerminalColor::Cyan,
                7 => TerminalColor::White,
                8 => TerminalColor::BrightBlack,
                9 => TerminalColor::BrightRed,
                10 => TerminalColor::BrightGreen,
                11 => TerminalColor::BrightYellow,
                12 => TerminalColor::BrightBlue,
                13 => TerminalColor::BrightMagenta,
                14 => TerminalColor::BrightCyan,
                15 => TerminalColor::BrightWhite,
                n => TerminalColor::Indexed(n),
            },
            CoreColor::Rgb(r, g, b) => TerminalColor::Rgb(*r, *g, *b),
        }
    }
}

/// Terminal handle for Swift interop
#[derive(uniffi::Object)]
pub struct TerminalHandle {
    terminal: Mutex<Terminal>,
}

#[uniffi::export]
impl TerminalHandle {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            terminal: Mutex::new(Terminal::new()),
        })
    }

    pub fn process_input(self: Arc<Self>, data: &[u8]) {
        let mut term = self.terminal.lock().unwrap();
        term.process_input(data);
    }

    pub fn rows(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.get_grid().rows() as u32
    }

    pub fn cols(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.get_grid().cols() as u32
    }

    pub fn cursor_row(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.get_cursor().row as u32
    }

    pub fn cursor_col(&self) -> u32 {
        let term = self.terminal.lock().unwrap();
        term.get_cursor().col as u32
    }

    pub fn cursor_visible(&self) -> bool {
        let term = self.terminal.lock().unwrap();
        term.get_cursor().visible
    }

    pub fn resize(&self, cols: u32, rows: u32) {
        let mut term = self.terminal.lock().unwrap();
        term.resize(cols as usize, rows as usize);
    }

    pub fn cell_at(&self, col: u32, row: u32) -> Option<TerminalCell> {
        let term = self.terminal.lock().unwrap();
        term.get_grid().get(col as usize, row as usize).map(|cell| {
            let content = if cell.ch == '\0' {
                " ".to_string()
            } else {
                cell.ch.to_string()
            };

            TerminalCell {
                content,
                foreground: TerminalColor::from(&cell.fg),
                background: TerminalColor::from(&cell.bg),
                bold: cell.attrs.bold,
                italic: cell.attrs.italic,
                underline: cell.attrs.underline,
                strikethrough: cell.attrs.strikethrough,
            }
        })
    }

    pub fn version(&self) -> String {
        env!("CARGO_PKG_VERSION").to_string()
    }
}

/// PTY Session handle
#[derive(uniffi::Object)]
pub struct PtySession {
    session: Mutex<CorePtySession>,
    terminal: Arc<TerminalHandle>,
}

#[uniffi::export]
impl PtySession {
    #[uniffi::constructor]
    pub fn new(cols: u32, rows: u32) -> Arc<Self> {
        let session =
            CorePtySession::new(cols as u16, rows as u16).expect("Failed to create PTY session");

        Arc::new(Self {
            terminal: TerminalHandle::new(),
            session: Mutex::new(session),
        })
    }

    pub fn write(&self, data: &[u8]) {
        let session = self.session.lock().unwrap();
        let _ = session.send_input(data);
    }

    pub fn read(&self) -> Vec<u8> {
        let session = self.session.lock().unwrap();
        session.receive_output()
    }

    pub fn resize(&self, cols: u32, rows: u32) {
        let session = self.session.lock().unwrap();
        let _ = session.resize(cols as u16, rows as u16);
    }

    pub fn is_alive(&self) -> bool {
        let session = self.session.lock().unwrap();
        session.is_alive()
    }

    pub fn get_terminal(&self) -> Arc<TerminalHandle> {
        Arc::clone(&self.terminal)
    }
}

/// Theme configuration
#[derive(uniffi::Record, Clone)]
pub struct Theme {
    pub name: String,
    pub background: Vec<u8>,
    pub foreground: Vec<u8>,
    pub cursor: Vec<u8>,
    pub selection: Vec<u8>,
    pub ansi_black: Vec<u8>,
    pub ansi_red: Vec<u8>,
    pub ansi_green: Vec<u8>,
    pub ansi_yellow: Vec<u8>,
    pub ansi_blue: Vec<u8>,
    pub ansi_magenta: Vec<u8>,
    pub ansi_cyan: Vec<u8>,
    pub ansi_white: Vec<u8>,
}

/// Theme manager
#[derive(uniffi::Object)]
pub struct ThemeManager;

#[uniffi::export]
impl ThemeManager {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }

    pub fn default_dark_theme(&self) -> Theme {
        Theme {
            name: "Opal Dark".to_string(),
            background: vec![30, 30, 30],
            foreground: vec![248, 248, 248],
            cursor: vec![255, 255, 255],
            selection: vec![60, 60, 60],
            ansi_black: vec![0, 0, 0],
            ansi_red: vec![205, 49, 49],
            ansi_green: vec![13, 188, 121],
            ansi_yellow: vec![229, 229, 16],
            ansi_blue: vec![36, 114, 200],
            ansi_magenta: vec![188, 63, 188],
            ansi_cyan: vec![17, 168, 205],
            ansi_white: vec![229, 229, 229],
        }
    }

    pub fn default_light_theme(&self) -> Theme {
        Theme {
            name: "Opal Light".to_string(),
            background: vec![255, 255, 255],
            foreground: vec![0, 0, 0],
            cursor: vec![0, 0, 0],
            selection: vec![200, 200, 200],
            ansi_black: vec![0, 0, 0],
            ansi_red: vec![205, 49, 49],
            ansi_green: vec![13, 188, 121],
            ansi_yellow: vec![229, 229, 16],
            ansi_blue: vec![36, 114, 200],
            ansi_magenta: vec![188, 63, 188],
            ansi_cyan: vec![17, 168, 205],
            ansi_white: vec![229, 229, 229],
        }
    }

    pub fn extract_from_image(&self, _image_path: String) -> Theme {
        // Placeholder implementation - auto-palette integration requires 'image' feature
        // For now, return a default dark theme
        self.default_dark_theme()
    }
}

/// Git commit info
#[derive(uniffi::Record, Clone)]
pub struct GitCommit {
    pub hash: String,
    pub message: String,
    pub author: String,
    pub timestamp: u64,
}

/// Git repository info
#[derive(uniffi::Record, Clone)]
pub struct GitInfo {
    pub is_repo: bool,
    pub branch: Option<String>,
    pub ahead: u32,
    pub behind: u32,
    pub modified: u32,
    pub staged: u32,
    pub untracked: u32,
}

/// Git manager
#[derive(uniffi::Object)]
pub struct GitManager;

impl GitManager {
    fn get_repo_info(path: &str) -> Result<GitInfo, git2::Error> {
        let repo = git2::Repository::discover(path)?;

        // Get current branch
        let head = repo.head()?;
        let branch = head.shorthand().map(|s| s.to_string());

        // Get status counts
        let mut modified = 0u32;
        let mut staged = 0u32;
        let mut untracked = 0u32;

        let statuses = repo.statuses(None)?;
        for entry in statuses.iter() {
            let status = entry.status();
            if status.contains(git2::Status::WT_NEW) {
                untracked += 1;
            } else if status.contains(git2::Status::INDEX_NEW)
                || status.contains(git2::Status::INDEX_MODIFIED)
                || status.contains(git2::Status::INDEX_DELETED)
                || status.contains(git2::Status::INDEX_RENAMED)
                || status.contains(git2::Status::INDEX_TYPECHANGE)
            {
                staged += 1;
            } else if status.contains(git2::Status::WT_MODIFIED)
                || status.contains(git2::Status::WT_DELETED)
                || status.contains(git2::Status::WT_RENAMED)
                || status.contains(git2::Status::WT_TYPECHANGE)
            {
                modified += 1;
            }
        }

        // Get ahead/behind count
        let (ahead, behind) = if let Some(branch_ref) = branch.as_ref() {
            Self::get_ahead_behind(&repo, branch_ref).unwrap_or((0, 0))
        } else {
            (0, 0)
        };

        Ok(GitInfo {
            is_repo: true,
            branch,
            ahead,
            behind,
            modified,
            staged,
            untracked,
        })
    }

    fn get_ahead_behind(repo: &git2::Repository, branch: &str) -> Result<(u32, u32), git2::Error> {
        let local = repo.find_branch(branch, git2::BranchType::Local)?;
        let local_ref = local.get().peel_to_commit()?;

        // Try to find upstream
        if let Ok(upstream) = local.upstream() {
            if let Ok(upstream_ref) = upstream.get().peel_to_commit() {
                let (ahead, behind) = repo.graph_ahead_behind(local_ref.id(), upstream_ref.id())?;
                return Ok((ahead as u32, behind as u32));
            }
        }

        Ok((0, 0))
    }

    fn get_recent_branches(path: &str, count: u32) -> Result<Vec<String>, git2::Error> {
        let repo = git2::Repository::discover(path)?;
        let mut branches = Vec::new();

        for branch in repo.branches(None)? {
            if let Ok((branch, _)) = branch {
                if let Some(name) = branch.name()? {
                    branches.push(name.to_string());
                    if branches.len() >= count as usize {
                        break;
                    }
                }
            }
        }

        Ok(branches)
    }

    fn get_recent_commits(path: &str, count: u32) -> Result<Vec<GitCommit>, git2::Error> {
        let repo = git2::Repository::discover(path)?;
        let mut commits = Vec::new();

        let head = repo.head()?;
        let oid = head
            .target()
            .ok_or_else(|| git2::Error::from_str("HEAD has no target"))?;

        let mut revwalk = repo.revwalk()?;
        revwalk.push(oid)?;
        revwalk.set_sorting(git2::Sort::TIME)?;

        for oid in revwalk.take(count as usize) {
            let oid = oid?;
            let commit = repo.find_commit(oid)?;

            let hash = commit.id().to_string();
            let message = commit
                .message()
                .unwrap_or("")
                .lines()
                .next()
                .unwrap_or("")
                .to_string();
            let author = commit.author().name().unwrap_or("Unknown").to_string();
            let timestamp = commit.time().seconds() as u64;

            commits.push(GitCommit {
                hash,
                message,
                author,
                timestamp,
            });
        }

        Ok(commits)
    }
}

#[uniffi::export]
impl GitManager {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }

    pub fn get_info(&self, path: String) -> GitInfo {
        Self::get_repo_info(&path).unwrap_or_else(|_| GitInfo {
            is_repo: false,
            branch: None,
            ahead: 0,
            behind: 0,
            modified: 0,
            staged: 0,
            untracked: 0,
        })
    }

    pub fn recent_branches(&self, path: String, count: u32) -> Vec<String> {
        Self::get_recent_branches(&path, count).unwrap_or_default()
    }

    pub fn recent_commits(&self, path: String, count: u32) -> Vec<GitCommit> {
        Self::get_recent_commits(&path, count).unwrap_or_default()
    }
}

/// Fuzzy match result
#[derive(uniffi::Record, Clone)]
pub struct FuzzyMatch {
    pub item: String,
    pub score: u32,
    pub indices: Vec<u32>,
}

/// Fuzzy matcher for command palette
#[derive(uniffi::Object)]
pub struct FuzzyMatcher {
    items: Mutex<Vec<String>>,
}

impl FuzzyMatcher {
    fn match_with_nucleo(items: &[String], query: &str) -> Vec<FuzzyMatch> {
        // For now, use simple substring matching with scoring
        // Full nucleo-matcher integration requires more complex setup
        if query.is_empty() {
            return items
                .iter()
                .enumerate()
                .map(|(idx, item)| FuzzyMatch {
                    item: item.clone(),
                    score: 100 - (idx as u32).min(100),
                    indices: Vec::new(),
                })
                .collect();
        }

        let query_lower = query.to_lowercase();
        let mut matches: Vec<FuzzyMatch> = items
            .iter()
            .filter_map(|item| {
                let item_lower = item.to_lowercase();
                if let Some(pos) = item_lower.find(&query_lower) {
                    // Calculate score based on match position and length
                    let position_score = 100 - (pos as u32).min(100);
                    let length_penalty = (item.len() as u32).saturating_sub(query.len() as u32);
                    let score = position_score.saturating_sub(length_penalty / 10);

                    // Generate indices for matched characters
                    let indices: Vec<u32> = (pos..pos + query.len()).map(|i| i as u32).collect();

                    Some(FuzzyMatch {
                        item: item.clone(),
                        score,
                        indices,
                    })
                } else {
                    None
                }
            })
            .collect();

        // Sort by score (higher is better)
        matches.sort_by(|a, b| b.score.cmp(&a.score));
        matches
    }
}

#[uniffi::export]
impl FuzzyMatcher {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            items: Mutex::new(Vec::new()),
        })
    }

    pub fn set_items(&self, items: Vec<String>) {
        let mut store = self.items.lock().unwrap();
        *store = items;
    }

    pub fn match_query(&self, query: String) -> Vec<FuzzyMatch> {
        let items = self.items.lock().unwrap();
        Self::match_with_nucleo(&items, &query)
    }
}

/// Command history
#[derive(uniffi::Object)]
pub struct CommandHistory {
    commands: Mutex<Vec<String>>,
}

#[uniffi::export]
impl CommandHistory {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            commands: Mutex::new(Vec::new()),
        })
    }

    pub fn add_command(&self, command: String) {
        let mut commands = self.commands.lock().unwrap();
        // Don't add duplicates at the top
        if commands.first() != Some(&command) {
            commands.insert(0, command);
            // Limit history size
            if commands.len() > 10000 {
                commands.truncate(10000);
            }
        }
    }

    pub fn recent_commands(&self, count: u32) -> Vec<String> {
        let commands = self.commands.lock().unwrap();
        commands.iter().take(count as usize).cloned().collect()
    }

    pub fn search(&self, query: String) -> Vec<FuzzyMatch> {
        let commands = self.commands.lock().unwrap();

        commands
            .iter()
            .enumerate()
            .filter_map(|(idx, cmd)| {
                if cmd.to_lowercase().contains(&query.to_lowercase()) {
                    Some(FuzzyMatch {
                        item: cmd.clone(),
                        score: 100 - (idx as u32).min(100),
                        indices: Vec::new(),
                    })
                } else {
                    None
                }
            })
            .collect()
    }
}

/// Get Opal version
#[uniffi::export]
pub fn opal_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

/// Callback interface for terminal updates
pub trait TerminalDelegate: Send + Sync {
    fn on_content_changed(&self);
    fn on_cursor_moved(&self, row: u32, col: u32);
    fn on_title_changed(&self, title: String);
}

/// FFI-compatible config struct
#[derive(uniffi::Record, Clone)]
pub struct ConfigFfi {
    pub font_family: String,
    pub font_size: f32,
    pub font_ligatures: bool,
    pub theme: String,
    pub transparency: f32,
    pub cursor_style: CursorStyleFfi,
    pub cursor_blinking: bool,
    pub scrollback: u32,
    pub ai_enabled: bool,
    pub ai_provider: String,
    pub ai_model: String,
}

#[derive(uniffi::Enum, Clone)]
pub enum CursorStyleFfi {
    Block,
    Underline,
    Line,
}

impl From<opal_core::CursorStyle> for CursorStyleFfi {
    fn from(style: opal_core::CursorStyle) -> Self {
        match style {
            opal_core::CursorStyle::Block => CursorStyleFfi::Block,
            opal_core::CursorStyle::Underline => CursorStyleFfi::Underline,
            opal_core::CursorStyle::Line => CursorStyleFfi::Line,
        }
    }
}

impl From<CursorStyleFfi> for opal_core::CursorStyle {
    fn from(style: CursorStyleFfi) -> Self {
        match style {
            CursorStyleFfi::Block => opal_core::CursorStyle::Block,
            CursorStyleFfi::Underline => opal_core::CursorStyle::Underline,
            CursorStyleFfi::Line => opal_core::CursorStyle::Line,
        }
    }
}

/// Config manager for Swift interop
#[derive(uniffi::Object)]
pub struct ConfigManager;

#[uniffi::export]
impl ConfigManager {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }

    pub fn load(&self) -> ConfigFfi {
        let config = opal_core::Config::load().unwrap_or_default();
        ConfigFfi {
            font_family: config.font.family,
            font_size: config.font.size,
            font_ligatures: config.font.ligatures,
            theme: config.theme,
            transparency: config.transparency,
            cursor_style: config.cursor.style.into(),
            cursor_blinking: config.cursor.blinking,
            scrollback: config.scrollback as u32,
            ai_enabled: config.ai.enabled,
            ai_provider: config.ai.provider,
            ai_model: config.ai.model,
        }
    }

    pub fn save(&self, config: ConfigFfi) -> bool {
        let core_config = opal_core::Config {
            font: opal_core::FontConfig {
                family: config.font_family,
                size: config.font_size,
                ligatures: config.font_ligatures,
            },
            theme: config.theme,
            transparency: config.transparency,
            cursor: opal_core::CursorConfig {
                style: config.cursor_style.into(),
                blinking: config.cursor_blinking,
            },
            scrollback: config.scrollback as usize,
            ai: opal_core::AiConfig {
                enabled: config.ai_enabled,
                provider: config.ai_provider,
                model: config.ai_model,
                api_key: None, // Don't expose API key through FFI
            },
            keybindings: std::collections::HashMap::new(), // Use defaults
        };
        core_config.save().is_ok()
    }

    pub fn default_config(&self) -> ConfigFfi {
        let config = opal_core::Config::default();
        ConfigFfi {
            font_family: config.font.family,
            font_size: config.font.size,
            font_ligatures: config.font.ligatures,
            theme: config.theme,
            transparency: config.transparency,
            cursor_style: config.cursor.style.into(),
            cursor_blinking: config.cursor.blinking,
            scrollback: config.scrollback as u32,
            ai_enabled: config.ai.enabled,
            ai_provider: config.ai.provider,
            ai_model: config.ai.model,
        }
    }
}
