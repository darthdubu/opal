pub mod terminal;
pub mod renderer;
pub mod ui;
pub mod sidebar;
pub mod config;
pub mod platform;

pub use config::Config;

pub fn init() -> Result<Config, anyhow::Error> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .format_timestamp_millis()
        .init();
    
    log::info!("Opal Terminal v{}", env!("CARGO_PKG_VERSION"));
    
    Config::load()
}
