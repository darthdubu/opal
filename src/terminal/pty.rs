use portable_pty::{native_pty_system, CommandBuilder, PtyPair, PtySize};
use std::io::Read;
use std::path::PathBuf;
use std::sync::mpsc::{channel, Sender};
use std::sync::Arc;
use std::thread;

pub struct Pty {
    pty_pair: Option<PtyPair>,
    master_write: Option<Arc<Sender<u8>>>,
    child_pid: Option<u32>,
    cwd: PathBuf,
}

impl Pty {
    pub fn new() -> Self {
        let pair = native_pty_system()
            .openpty(PtySize {
                rows: 24,
                cols: 80,
                pixel_width: 0,
                pixel_height: 0,
            })
            .ok();

        let master_write = if pair.is_some() {
            let (tx, _rx) = channel::<u8>();
            Some(Arc::new(tx))
        } else {
            None
        };

        Self {
            pty_pair: pair,
            master_write,
            child_pid: None,
            cwd: std::env::current_dir().unwrap_or_else(|_| PathBuf::from("/")),
        }
    }

    pub fn spawn(&mut self, shell: Option<&str>) -> Result<u32, Box<dyn std::error::Error>> {
        let pair = self.pty_pair.as_mut().ok_or("PTY not initialized")?;

        let shell_path = match shell {
            Some(s) => s.to_string(),
            None => std::env::var("SHELL").unwrap_or_else(|_| "/bin/bash".to_string()),
        };
        let mut cmd = CommandBuilder::new(shell_path.as_str());

        cmd.cwd(&self.cwd);
        cmd.env("TERM", "xterm-256color");

        let child = pair.slave.spawn_command(cmd)?;
        let pid = child.process_id().ok_or("Failed to get process ID")?;
        self.child_pid = Some(pid);

        let mut master = pair.master.try_clone_reader()?;

        if let Some(tx) = &self.master_write {
            let tx = tx.clone();
            thread::spawn(move || {
                let mut buf = [0u8; 4096];
                loop {
                    match master.read(&mut buf) {
                        Ok(0) => break,
                        Ok(n) => {
                            for byte in &buf[..n] {
                                let _ = tx.send(*byte);
                            }
                        }
                        Err(_) => break,
                    }
                }
            });
        }

        Ok(pid)
    }

    pub fn resize(&mut self, cols: u16, rows: u16) -> Result<(), Box<dyn std::error::Error>> {
        if let Some(pair) = &self.pty_pair {
            pair.master.resize(PtySize {
                rows,
                cols,
                pixel_width: 0,
                pixel_height: 0,
            })?;
        }
        Ok(())
    }

    pub fn write(&self, data: &[u8]) -> Result<(), Box<dyn std::error::Error>> {
        if let Some(writer) = &self.master_write {
            for &byte in data {
                writer.send(byte)?;
            }
        }
        Ok(())
    }

    pub fn try_read(&self) -> Option<u8> {
        None
    }

    pub fn get_cwd(&self) -> &PathBuf {
        &self.cwd
    }

    pub fn set_cwd(&mut self, cwd: PathBuf) {
        self.cwd = cwd;
    }

    pub fn wait(&mut self) -> Result<u32, Box<dyn std::error::Error>> {
        if let Some(pid) = self.child_pid {
            // In a real implementation, we'd wait for the process
            Ok(pid)
        } else {
            Err("No child process".into())
        }
    }
}

impl Default for Pty {
    fn default() -> Self {
        Self::new()
    }
}
