use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum KeyModifier {
    Command,
    Option,
    Control,
    Shift,
    Function,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct KeyCombo {
    pub key: Key,
    pub modifiers: Vec<KeyModifier>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Key {
    Character(char),
    Function(u8),
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    Enter,
    Tab,
    Escape,
    Backspace,
    Delete,
    Home,
    End,
    PageUp,
    PageDown,
    Insert,
}

pub struct MenuItem {
    pub id: String,
    pub label: String,
    pub shortcut: Option<KeyCombo>,
    pub enabled: bool,
    pub action: Option<MenuAction>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum MenuAction {
    NewTab,
    CloseTab,
    NextTab,
    PreviousTab,
    ToggleSidebar,
    Preferences,
    Quit,
    NewWindow,
    SplitVertical,
    SplitHorizontal,
    CloseSplit,
    Copy,
    Paste,
    SelectAll,
    ClearTerminal,
    Find,
    About,
}

pub struct Menu {
    pub id: String,
    pub label: String,
    pub items: Vec<MenuItem>,
    pub submenus: HashMap<String, Menu>,
}

impl Menu {
    pub fn new(id: &str, label: &str) -> Self {
        Self {
            id: id.to_string(),
            label: label.to_string(),
            items: Vec::new(),
            submenus: HashMap::new(),
        }
    }

    pub fn add_item(&mut self, item: MenuItem) {
        self.items.push(item);
    }

    pub fn add_submenu(&mut self, menu: Menu) {
        self.submenus.insert(menu.id.clone(), menu);
    }
}

pub struct MenuBar {
    pub menus: Vec<Menu>,
    keybindings: HashMap<KeyCombo, MenuAction>,
}

impl MenuBar {
    pub fn new() -> Self {
        let mut bar = Self {
            menus: Vec::new(),
            keybindings: HashMap::new(),
        };
        bar.setup_default_menus();
        bar
    }

    fn setup_default_menus(&mut self) {
        let mut file_menu = Menu::new("file", "File");

        file_menu.items.push(MenuItem {
            id: "new_tab".to_string(),
            label: "New Tab".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('t'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::NewTab),
        });

        file_menu.items.push(MenuItem {
            id: "new_window".to_string(),
            label: "New Window".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('n'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::NewWindow),
        });

        file_menu.items.push(MenuItem {
            id: "close_tab".to_string(),
            label: "Close Tab".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('w'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::CloseTab),
        });

        file_menu.items.push(MenuItem {
            id: "quit".to_string(),
            label: "Quit Opal".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('q'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::Quit),
        });

        self.menus.push(file_menu);

        let mut edit_menu = Menu::new("edit", "Edit");

        edit_menu.items.push(MenuItem {
            id: "copy".to_string(),
            label: "Copy".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('c'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::Copy),
        });

        edit_menu.items.push(MenuItem {
            id: "paste".to_string(),
            label: "Paste".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('v'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::Paste),
        });

        edit_menu.items.push(MenuItem {
            id: "select_all".to_string(),
            label: "Select All".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('a'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::SelectAll),
        });

        self.menus.push(edit_menu);

        let mut view_menu = Menu::new("view", "View");

        view_menu.items.push(MenuItem {
            id: "toggle_sidebar".to_string(),
            label: "Toggle Sidebar".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('s'),
                modifiers: vec![KeyModifier::Command, KeyModifier::Option],
            }),
            enabled: true,
            action: Some(MenuAction::ToggleSidebar),
        });

        view_menu.items.push(MenuItem {
            id: "preferences".to_string(),
            label: "Preferences...".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character(','),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::Preferences),
        });

        self.menus.push(view_menu);

        let mut tab_menu = Menu::new("tab", "Tab");

        tab_menu.items.push(MenuItem {
            id: "next_tab".to_string(),
            label: "Next Tab".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('}'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::NextTab),
        });

        tab_menu.items.push(MenuItem {
            id: "previous_tab".to_string(),
            label: "Previous Tab".to_string(),
            shortcut: Some(KeyCombo {
                key: Key::Character('{'),
                modifiers: vec![KeyModifier::Command],
            }),
            enabled: true,
            action: Some(MenuAction::PreviousTab),
        });

        self.menus.push(tab_menu);

        let mut help_menu = Menu::new("help", "Help");

        help_menu.items.push(MenuItem {
            id: "about".to_string(),
            label: "About Opal".to_string(),
            shortcut: None,
            enabled: true,
            action: Some(MenuAction::About),
        });

        self.menus.push(help_menu);
    }

    pub fn register_keybinding(&mut self, combo: KeyCombo, action: MenuAction) {
        self.keybindings.insert(combo, action);
    }

    pub fn lookup_keybinding(&self, key: Key, modifiers: &[KeyModifier]) -> Option<MenuAction> {
        let combo = KeyCombo {
            key,
            modifiers: modifiers.to_vec(),
        };
        self.keybindings.get(&combo).copied()
    }
}

impl Default for MenuBar {
    fn default() -> Self {
        Self::new()
    }
}
