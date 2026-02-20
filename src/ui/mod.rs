use crate::config::Config;
use crate::renderer::Renderer;
use crate::sidebar::Sidebar;
use crate::terminal::Terminal;
use std::path::PathBuf;

pub mod menu;
pub use menu::*;

pub struct Tab {
    pub id: u64,
    pub title: String,
    pub terminal: Terminal,
    pub cwd: PathBuf,
    pub is_active: bool,
}

impl Tab {
    pub fn new(id: u64, cwd: PathBuf) -> Self {
        Self {
            id,
            title: "Terminal".to_string(),
            terminal: Terminal::new(),
            cwd,
            is_active: false,
        }
    }

    pub fn set_active(&mut self, active: bool) {
        self.is_active = active;
        if active {
            self.title = self
                .cwd
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_else(|| "Terminal".to_string());
        }
    }
}

pub struct TabGroup {
    tabs: Vec<Tab>,
    active_tab_id: u64,
    next_tab_id: u64,
}

impl TabGroup {
    pub fn new() -> Self {
        Self {
            tabs: Vec::new(),
            active_tab_id: 0,
            next_tab_id: 1,
        }
    }

    pub fn add_tab(&mut self, cwd: PathBuf) -> u64 {
        let id = self.next_tab_id;
        self.next_tab_id += 1;

        let mut tab = Tab::new(id, cwd);
        tab.set_active(self.tabs.is_empty());

        if let Some(active) = self.tabs.iter_mut().find(|t| t.is_active) {
            active.set_active(false);
        }

        self.active_tab_id = id;
        self.tabs.push(tab);

        id
    }

    pub fn close_tab(&mut self, id: u64) -> bool {
        if let Some(pos) = self.tabs.iter().position(|t| t.id == id) {
            self.tabs.remove(pos);

            if self.tabs.is_empty() {
                return false;
            }

            if self.active_tab_id == id {
                let new_active = self.tabs.len() - 1;
                self.tabs[new_active].set_active(true);
                self.active_tab_id = self.tabs[new_active].id;
            }

            return true;
        }
        false
    }

    pub fn set_active_tab(&mut self, id: u64) {
        for tab in &mut self.tabs {
            tab.set_active(tab.id == id);
        }
        self.active_tab_id = id;
    }

    pub fn active_tab(&self) -> Option<&Tab> {
        self.tabs.iter().find(|t| t.id == self.active_tab_id)
    }

    pub fn active_tab_mut(&mut self) -> Option<&mut Tab> {
        self.tabs.iter_mut().find(|t| t.id == self.active_tab_id)
    }

    pub fn tabs(&self) -> &[Tab] {
        &self.tabs
    }

    pub fn tabs_mut(&mut self) -> &mut Vec<Tab> {
        &mut self.tabs
    }

    pub fn next_tab(&mut self) {
        if self.tabs.len() <= 1 {
            return;
        }

        let current_pos = self
            .tabs
            .iter()
            .position(|t| t.id == self.active_tab_id)
            .unwrap_or(0);

        let next_pos = (current_pos + 1) % self.tabs.len();
        self.set_active_tab(self.tabs[next_pos].id);
    }

    pub fn previous_tab(&mut self) {
        if self.tabs.len() <= 1 {
            return;
        }

        let current_pos = self
            .tabs
            .iter()
            .position(|t| t.id == self.active_tab_id)
            .unwrap_or(0);

        let prev_pos = if current_pos == 0 {
            self.tabs.len() - 1
        } else {
            current_pos - 1
        };

        self.set_active_tab(self.tabs[prev_pos].id);
    }
}

impl Default for TabGroup {
    fn default() -> Self {
        Self::new()
    }
}

pub struct SplitPane {
    pub vertical: bool,
    pub children: Vec<SplitNode>,
    pub sizes: Vec<f32>,
}

pub enum SplitNode {
    Leaf(usize),
    Branch(Box<SplitPane>),
}

impl SplitPane {
    pub fn new(vertical: bool, count: usize) -> Self {
        let sizes = vec![1.0 / count as f32; count];

        Self {
            vertical,
            children: (0..count).map(|i| SplitNode::Leaf(i)).collect(),
            sizes,
        }
    }

    pub fn adjust_size(&mut self, index: usize, delta: f32) {
        if index >= self.sizes.len() {
            return;
        }

        self.sizes[index] = (self.sizes[index] + delta).clamp(0.1, 0.9);

        let total: f32 = self.sizes.iter().sum();
        for size in &mut self.sizes {
            *size /= total;
        }
    }
}

pub struct App {
    pub config: Config,
    pub tabs: TabGroup,
    pub sidebar: Option<Sidebar>,
    pub renderer: Renderer,
    pub focused_element: FocusElement,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum FocusElement {
    Terminal,
    Sidebar,
    TabBar,
}

impl App {
    pub fn new(config: Config) -> Self {
        let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("/"));

        let mut tabs = TabGroup::new();
        tabs.add_tab(cwd.clone());

        let sidebar = if config.show_sidebar {
            Some(Sidebar::new(cwd))
        } else {
            None
        };

        let renderer = Renderer::new();

        Self {
            config,
            tabs,
            sidebar,
            renderer,
            focused_element: FocusElement::Terminal,
        }
    }

    pub fn run(&self) -> Result<(), anyhow::Error> {
        log::info!("Starting Opal Terminal");

        #[cfg(target_os = "macos")]
        {
            use std::process::Command;

            Command::new("osascript")
                .args([
                    "-e",
                    "tell app \"Terminal\" to do script \"echo 'Welcome to Opal Terminal v0.1.0'\"",
                ])
                .spawn()
                .ok();
        }

        Ok(())
    }

    pub fn new_tab(&mut self, cwd: PathBuf) {
        self.tabs.add_tab(cwd);
    }

    pub fn close_active_tab(&mut self) {
        let active_id = self.tabs.active_tab_id;
        self.tabs.close_tab(active_id);
    }

    pub fn toggle_sidebar(&mut self) {
        if let Some(sidebar) = &mut self.sidebar {
            sidebar.toggle();
        }
    }

    pub fn focus_next(&mut self) {
        self.focused_element = match self.focused_element {
            FocusElement::Terminal => {
                if self.sidebar.is_some() {
                    FocusElement::Sidebar
                } else {
                    FocusElement::TabBar
                }
            }
            FocusElement::Sidebar => FocusElement::TabBar,
            FocusElement::TabBar => FocusElement::Terminal,
        };
    }

    pub fn focus_previous(&mut self) {
        self.focused_element = match self.focused_element {
            FocusElement::Terminal => FocusElement::TabBar,
            FocusElement::Sidebar => FocusElement::Terminal,
            FocusElement::TabBar => {
                if self.sidebar.is_some() {
                    FocusElement::Sidebar
                } else {
                    FocusElement::Terminal
                }
            }
        };
    }
}
