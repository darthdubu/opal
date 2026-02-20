pub struct FileBrowser;

impl FileBrowser {
    pub fn new() -> Self {
        Self
    }

    pub fn refresh(&mut self) {
        unimplemented!("File browser")
    }
}

pub struct GitIntegration;

impl GitIntegration {
    pub fn new() -> Self {
        Self
    }

    pub fn status(&self) {
        unimplemented!("Git integration")
    }
}
