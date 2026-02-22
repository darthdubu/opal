use std::sync::{Arc, Mutex};

#[derive(uniffi::Object)]
pub struct RendererHandle {
    state: Mutex<RendererState>,
}

struct RendererState {
    width: u32,
    height: u32,
    initialized: bool,
}

#[uniffi::export]
impl RendererHandle {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            state: Mutex::new(RendererState {
                width: 800,
                height: 600,
                initialized: false,
            }),
        })
    }

    pub fn initialize_with_metal_device(&self, device_ptr: u64) -> bool {
        let mut state = self.state.lock().unwrap();
        state.initialized = true;
        println!(
            "Renderer initialized with Metal device: 0x{:016x}",
            device_ptr
        );
        true
    }

    pub fn resize(&self, width: u32, height: u32) {
        let mut state = self.state.lock().unwrap();
        state.width = width;
        state.height = height;
    }

    pub fn render_frame(&self) -> bool {
        let state = self.state.lock().unwrap();
        if !state.initialized {
            return false;
        }
        true
    }

    pub fn get_width(&self) -> u32 {
        let state = self.state.lock().unwrap();
        state.width
    }

    pub fn get_height(&self) -> u32 {
        let state = self.state.lock().unwrap();
        state.height
    }
}

#[derive(uniffi::Record, Clone)]
pub struct RenderCell {
    pub content: String,
    pub fg_color: Vec<u8>,
    pub bg_color: Vec<u8>,
}

#[derive(uniffi::Record, Clone)]
pub struct RenderRow {
    pub cells: Vec<RenderCell>,
}

#[derive(uniffi::Object)]
pub struct TerminalRenderer {
    handle: Arc<RendererHandle>,
    rows: Mutex<Vec<RenderRow>>,
}

#[uniffi::export]
impl TerminalRenderer {
    #[uniffi::constructor]
    pub fn new(handle: Arc<RendererHandle>) -> Arc<Self> {
        Arc::new(Self {
            handle,
            rows: Mutex::new(Vec::new()),
        })
    }

    pub fn update_content(&self, rows: Vec<RenderRow>) {
        let mut stored_rows = self.rows.lock().unwrap();
        *stored_rows = rows;
    }

    pub fn render(&self) -> bool {
        let _rows = self.rows.lock().unwrap();
        self.handle.render_frame()
    }
}
