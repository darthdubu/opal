use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub font: FontConfig,
    pub theme: String,
    pub transparency: f32,
    pub cursor: CursorConfig,
    pub scrollback: usize,
    pub ai: AiConfig,
    pub keybindings: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FontConfig {
    pub family: String,
    pub size: f32,
    pub ligatures: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CursorConfig {
    pub style: CursorStyle,
    pub blinking: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CursorStyle {
    Block,
    Underline,
    Line,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiConfig {
    pub enabled: bool,
    pub provider: String,
    pub model: String,
    pub api_key: Option<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            font: FontConfig {
                family: "SF Mono".to_string(),
                size: 14.0,
                ligatures: true,
            },
            theme: "opal-dark".to_string(),
            transparency: 0.85,
            cursor: CursorConfig {
                style: CursorStyle::Block,
                blinking: true,
            },
            scrollback: 10000,
            ai: AiConfig {
                enabled: true,
                provider: "ollama".to_string(),
                model: "codellama".to_string(),
                api_key: None,
            },
            keybindings: default_keybindings(),
        }
    }
}

impl Config {
    pub fn load() -> anyhow::Result<Self> {
        let config_path = config_path()?;

        if !config_path.exists() {
            let config = Config::default();
            config.save()?;
            return Ok(config);
        }

        let content = fs::read_to_string(config_path)?;
        let config: Config = toml::from_str(&content)?;
        Ok(config)
    }

    pub fn save(&self) -> anyhow::Result<()> {
        let config_path = config_path()?;

        if let Some(parent) = config_path.parent() {
            fs::create_dir_all(parent)?;
        }

        let content = toml::to_string_pretty(self)?;
        fs::write(config_path, content)?;
        Ok(())
    }
}

fn config_path() -> anyhow::Result<PathBuf> {
    let home = dirs::home_dir().ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?;
    Ok(home.join(".config").join("opal").join("config.toml"))
}

fn default_keybindings() -> HashMap<String, String> {
    let mut bindings = HashMap::new();
    bindings.insert("new_tab".to_string(), "Cmd+T".to_string());
    bindings.insert("close_tab".to_string(), "Cmd+W".to_string());
    bindings.insert("next_tab".to_string(), "Cmd+Shift+]".to_string());
    bindings.insert("prev_tab".to_string(), "Cmd+Shift+[".to_string());
    bindings.insert("command_palette".to_string(), "Cmd+Shift+P".to_string());
    bindings.insert("ai_chat".to_string(), "Cmd+1".to_string());
    bindings.insert("sessions".to_string(), "Cmd+2".to_string());
    bindings.insert("navigator".to_string(), "Cmd+3".to_string());
    bindings.insert("history".to_string(), "Cmd+4".to_string());
    bindings
}
