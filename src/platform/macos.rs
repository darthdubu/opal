pub fn init_app() -> Result<(), anyhow::Error> {
    Ok(())
}

pub fn run_app() {
    use std::process::Command;
    let _ = Command::new("osascript")
        .args([
            "-e",
            "tell application \"System Events\" to keystroke \"t\" using command down",
        ])
        .output();
}
