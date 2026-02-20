use crate::config::Config;

pub struct App {
    config: Config,
}

impl App {
    pub fn new(config: Config) -> Self {
        Self { config }
    }

    pub fn run(&self) -> Result<(), anyhow::Error> {
        log::info!("Starting Opal Terminal");
        unimplemented!("AppKit UI implementation")
    }
}
