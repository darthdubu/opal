use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub font_family: String,
    pub font_size: f32,
    pub theme: Theme,
    pub editor: String,
    pub sidebar_width: u32,
    pub show_sidebar: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub name: String,
    pub background_alpha: f32,
    pub blur_radius: f32,
    pub foreground: String,
    pub background: String,
    pub cursor: String,
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            name: "Liquid Glass".to_string(),
            background_alpha: 0.8,
            blur_radius: 20.0,
            foreground: "#ffffff".to_string(),
            background: "#1e1e1e".to_string(),
            cursor: "#ffffff".to_string(),
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            font_family: "SF Mono".to_string(),
            font_size: 12.0,
            theme: Theme::default(),
            editor: "micro".to_string(),
            sidebar_width: 250,
            show_sidebar: true,
        }
    }
}

impl Config {
    pub fn load() -> Result<Self, anyhow::Error> {
        let config_dir = directories::ProjectDirs::from("com", "opal", "opal")
            .map(|d| d.config_dir().to_path_buf())
            .unwrap_or_else(|| std::env::current_dir().unwrap());

        let config_path = config_dir.join("config.json");

        if config_path.exists() {
            let content = std::fs::read_to_string(&config_path)?;
            let config: Config = serde_json::from_str(&content)?;
            Ok(config)
        } else {
            let config = Config::default();
            if let Some(parent) = config_path.parent() {
                std::fs::create_dir_all(parent)?;
            }
            let content = serde_json::to_string_pretty(&config)?;
            std::fs::write(&config_path, content)?;
            Ok(config)
        }
    }

    pub fn save(&self) -> Result<(), anyhow::Error> {
        let config_dir = directories::ProjectDirs::from("com", "opal", "opal")
            .map(|d| d.config_dir().to_path_buf())
            .unwrap_or_else(|| std::env::current_dir().unwrap());

        let config_path = config_dir.join("config.json");

        if let Some(parent) = config_path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(&config_path, content)?;
        Ok(())
    }
}
