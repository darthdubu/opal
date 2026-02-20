use opal::init;
use opal::ui::App;

fn main() {
    match init() {
        Ok(config) => {
            if let Err(e) = App::new(config).run() {
                log::error!("Application error: {}", e);
                std::process::exit(1);
            }
        }
        Err(e) => {
            eprintln!("Failed to initialize Opal: {}", e);
            std::process::exit(1);
        }
    }
}
