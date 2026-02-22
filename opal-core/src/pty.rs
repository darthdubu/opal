use portable_pty::ExitStatus;
use portable_pty::{Child, MasterPty, PtySize};
use std::io::{Read, Write};
use std::sync::mpsc::{channel, Receiver};
use std::sync::{Arc, Mutex};

pub struct Pty {
    master: Box<dyn MasterPty + Send>,
    child: Arc<Mutex<Box<dyn Child + Send>>>,
    writer: Arc<Mutex<Box<dyn Write + Send>>>,
    receiver: Receiver<Vec<u8>>,
}

impl Pty {
    pub fn new(cols: u16, rows: u16) -> anyhow::Result<Self> {
        let pty_system = portable_pty::native_pty_system();

        let pair = pty_system.openpty(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })?;

        let mut cmd = portable_pty::CommandBuilder::new("/bin/zsh");
        cmd.env("TERM", "xterm-256color");
        cmd.env("TERM_PROGRAM", "Opal");
        cmd.env("TERM_PROGRAM_VERSION", "1.0.0");

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
        cmd.env("SHELL", "/bin/zsh");

        // Set LANG for proper locale
        cmd.env("LANG", "en_US.UTF-8");

        let child = pair.slave.spawn_command(cmd)?;

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

        Ok(Self {
            master: pair.master,
            child: Arc::new(Mutex::new(child)),
            writer: Arc::new(Mutex::new(writer)),
            receiver,
        })
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
}

impl PtySession {
    pub fn new(cols: u16, rows: u16) -> anyhow::Result<Self> {
        let pty = Arc::new(Pty::new(cols, rows)?);
        Ok(Self { pty })
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
}

// SAFETY: Pty is Send + Sync because all its fields are thread-safe
unsafe impl Send for Pty {}
unsafe impl Sync for Pty {}

// SAFETY: PtySession is Send + Sync because Pty is Send + Sync
unsafe impl Send for PtySession {}
unsafe impl Sync for PtySession {}
