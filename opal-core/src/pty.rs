use portable_pty::ExitStatus;
use portable_pty::{Child, MasterPty, PtySize};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Receiver};
use std::sync::{Arc, Mutex};

const OPAL_VERSION: &str = "1.3.1";

#[derive(Clone, Debug, Default)]
pub struct ShellRuntimeStatus {
    pub active_shell: String,
    pub active_shell_path: String,
    pub attempted_shell_path: String,
    pub fallback_reason: String,
    pub seashell_version: String,
}

pub struct Pty {
    master: Box<dyn MasterPty + Send>,
    child: Arc<Mutex<Box<dyn Child + Send>>>,
    writer: Arc<Mutex<Box<dyn Write + Send>>>,
    receiver: Receiver<Vec<u8>>,
}

impl Pty {
    pub fn new(cols: u16, rows: u16) -> anyhow::Result<Self> {
        let (pty, _) = Self::new_with_shell(cols, rows, None)?;
        Ok(pty)
    }

    pub fn new_with_shell(
        cols: u16,
        rows: u16,
        preferred_shell: Option<&str>,
    ) -> anyhow::Result<(Self, ShellRuntimeStatus)> {
        let pty_system = portable_pty::native_pty_system();

        let pair = pty_system.openpty(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })?;

        let resolved = resolve_shell(preferred_shell);
        let attempted_shell_path = resolved.path.to_string_lossy().to_string();
        let mut fallback_reason = String::new();

        let mut cmd = portable_pty::CommandBuilder::new(resolved.path.to_string_lossy().as_ref());
        for arg in &resolved.args {
            cmd.arg(arg);
        }
        cmd.env("TERM", "xterm-256color");
        cmd.env("TERM_PROGRAM", "Opal");
        cmd.env("TERM_PROGRAM_VERSION", OPAL_VERSION);

        // Get PATH from current process or use default macOS PATH
        let path = std::env::var("PATH").unwrap_or_else(|_| {
            "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin"
                .to_string()
        });
        cmd.env("PATH", path);

        // Set other important environment variables
        if let Ok(home) = std::env::var("HOME") {
            cmd.env("HOME", home);
        }
        if let Ok(user) = std::env::var("USER") {
            cmd.env("USER", user);
        }
        cmd.env("SHELL", resolved.path.to_string_lossy().as_ref());

        // Set LANG for proper locale
        cmd.env("LANG", "en_US.UTF-8");

        let child = match pair.slave.spawn_command(cmd) {
            Ok(child) => child,
            Err(err) if resolved.shell_name == "seashell" => {
                fallback_reason = format!("Bundled Seashell failed: {}", err);
                let mut zsh_cmd = portable_pty::CommandBuilder::new("/bin/zsh");
                zsh_cmd.arg("-l");
                zsh_cmd.env("TERM", "xterm-256color");
                zsh_cmd.env("TERM_PROGRAM", "Opal");
                zsh_cmd.env("TERM_PROGRAM_VERSION", OPAL_VERSION);
                if let Ok(home) = std::env::var("HOME") {
                    zsh_cmd.env("HOME", home);
                }
                if let Ok(user) = std::env::var("USER") {
                    zsh_cmd.env("USER", user);
                }
                zsh_cmd.env("SHELL", "/bin/zsh");
                zsh_cmd.env("LANG", "en_US.UTF-8");
                zsh_cmd.env(
                    "PATH",
                    std::env::var("PATH").unwrap_or_else(|_| {
                        "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin"
                            .to_string()
                    }),
                );
                zsh_cmd.env("OPAL_SHELL_FALLBACK_REASON", fallback_reason.clone());
                pair.slave.spawn_command(zsh_cmd)?
            }
            Err(err) => return Err(err),
        };

        let reader = pair.master.try_clone_reader()?;
        let writer = pair.master.take_writer()?;

        // Spawn background reader thread
        let (sender, receiver) = channel::<Vec<u8>>();
        std::thread::spawn(move || {
            let mut reader = reader;
            let mut buf = [0u8; 1024];
            loop {
                match reader.read(&mut buf) {
                    Ok(0) => {
                        // EOF - PTY closed
                        break;
                    }
                    Ok(n) => {
                        let _ = sender.send(buf[..n].to_vec());
                    }
                    Err(_) => {
                        // Error reading - exit thread
                        break;
                    }
                }
            }
        });

        let active_shell = if fallback_reason.is_empty() {
            resolved.shell_name.to_string()
        } else {
            "zsh".to_string()
        };
        let active_shell_path = if fallback_reason.is_empty() {
            resolved.path.to_string_lossy().to_string()
        } else {
            "/bin/zsh".to_string()
        };
        let status = ShellRuntimeStatus {
            active_shell,
            active_shell_path,
            attempted_shell_path,
            fallback_reason,
            seashell_version: resolved.seashell_version,
        };

        Ok((
            Self {
                master: pair.master,
                child: Arc::new(Mutex::new(child)),
                writer: Arc::new(Mutex::new(writer)),
                receiver,
            },
            status,
        ))
    }

    pub fn write(&self, data: &[u8]) -> std::io::Result<()> {
        self.writer.lock().unwrap().write_all(data)
    }

    /// Non-blocking read - returns immediately with any available data
    pub fn read_available(&self) -> Vec<u8> {
        let mut result = Vec::new();
        // Drain all available messages from the channel without blocking
        while let Ok(data) = self.receiver.try_recv() {
            result.extend_from_slice(&data);
        }
        result
    }

    pub fn resize(&self, cols: u16, rows: u16) -> anyhow::Result<()> {
        self.master.resize(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })?;
        Ok(())
    }

    pub fn exit_status(&self) -> anyhow::Result<Option<ExitStatus>> {
        self.child.lock().unwrap().try_wait().map_err(|e| e.into())
    }

    pub fn is_alive(&self) -> bool {
        matches!(self.exit_status(), Ok(None))
    }
}

pub struct PtySession {
    pty: Arc<Pty>,
    shell_status: ShellRuntimeStatus,
}

impl PtySession {
    pub fn new(cols: u16, rows: u16) -> anyhow::Result<Self> {
        Self::new_with_shell(cols, rows, None)
    }

    pub fn new_with_shell(
        cols: u16,
        rows: u16,
        preferred_shell: Option<&str>,
    ) -> anyhow::Result<Self> {
        let (pty, shell_status) = Pty::new_with_shell(cols, rows, preferred_shell)?;
        let pty = Arc::new(pty);
        Ok(Self { pty, shell_status })
    }

    pub fn send_input(&self, data: &[u8]) -> std::io::Result<()> {
        self.pty.write(data)
    }

    /// Non-blocking read - returns immediately with any available data
    pub fn receive_output(&self) -> Vec<u8> {
        self.pty.read_available()
    }

    pub fn resize(&self, cols: u16, rows: u16) -> anyhow::Result<()> {
        self.pty.resize(cols, rows)
    }

    pub fn is_alive(&self) -> bool {
        self.pty.is_alive()
    }

    pub fn get_pty(&self) -> Arc<Pty> {
        Arc::clone(&self.pty)
    }

    pub fn shell_status(&self) -> &ShellRuntimeStatus {
        &self.shell_status
    }
}

// SAFETY: Pty is Send + Sync because all its fields are thread-safe
unsafe impl Send for Pty {}
unsafe impl Sync for Pty {}

// SAFETY: PtySession is Send + Sync because Pty is Send + Sync
unsafe impl Send for PtySession {}
unsafe impl Sync for PtySession {}

struct ResolvedShell {
    shell_name: &'static str,
    path: PathBuf,
    args: Vec<&'static str>,
    seashell_version: String,
}

fn resolve_shell(preferred_shell: Option<&str>) -> ResolvedShell {
    let prefer_zsh = matches!(preferred_shell, Some("zsh"));
    if !prefer_zsh {
        if let Some(path) = resolve_seashell_path() {
            return ResolvedShell {
                shell_name: "seashell",
                seashell_version: read_seashell_version(&path),
                path,
                args: Vec::new(),
            };
        }
    }

    ResolvedShell {
        shell_name: "zsh",
        path: PathBuf::from("/bin/zsh"),
        args: vec!["-l"],
        seashell_version: String::new(),
    }
}

fn resolve_seashell_path() -> Option<PathBuf> {
    if let Ok(override_path) = std::env::var("OPAL_SEASHELL_PATH") {
        let path = PathBuf::from(override_path);
        if is_executable(&path) {
            return Some(path);
        }
    }

    if let Ok(override_path) = std::env::var("OPAL_SEASHELL_OVERRIDE") {
        let path = PathBuf::from(override_path);
        if is_executable(&path) {
            return Some(path);
        }
    }

    if let Ok(bundled) = std::env::var("OPAL_BUNDLED_SEASHELL") {
        let path = PathBuf::from(bundled);
        if is_executable(&path) {
            return Some(path);
        }
    }

    let sibling = PathBuf::from("../seashell/sea");
    if is_executable(&sibling) {
        return Some(sibling);
    }

    find_in_path("sea").filter(|candidate| !is_probably_cargo_wrapper(candidate))
}

fn is_executable(path: &Path) -> bool {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        if let Ok(meta) = std::fs::metadata(path) {
            let mode = meta.permissions().mode();
            return meta.is_file() && (mode & 0o111 != 0);
        }
    }

    #[allow(unreachable_code)]
    false
}

fn find_in_path(executable: &str) -> Option<PathBuf> {
    let path_var = std::env::var("PATH").ok()?;
    for dir in path_var.split(':') {
        if dir.is_empty() {
            continue;
        }
        let candidate = Path::new(dir).join(executable);
        if is_executable(&candidate) {
            return Some(candidate);
        }
    }
    None
}

fn is_probably_cargo_wrapper(path: &Path) -> bool {
    let meta = match std::fs::metadata(path) {
        Ok(meta) => meta,
        Err(_) => return false,
    };

    // Wrapper scripts are small; avoid scanning large binaries.
    if meta.len() > 64 * 1024 {
        return false;
    }

    let bytes = match std::fs::read(path) {
        Ok(bytes) => bytes,
        Err(_) => return false,
    };

    let has_shebang = bytes.starts_with(b"#!");
    let has_cargo_run = bytes.windows(b"cargo run".len()).any(|w| w == b"cargo run");
    let has_sea_cli = bytes.windows(b"sea-cli".len()).any(|w| w == b"sea-cli");
    has_shebang && has_cargo_run && has_sea_cli
}

fn read_seashell_version(shell_path: &Path) -> String {
    let version_path = shell_path
        .parent()
        .map(|p| p.join("VERSION"))
        .unwrap_or_else(|| PathBuf::from("VERSION"));
    std::fs::read_to_string(version_path)
        .ok()
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}
