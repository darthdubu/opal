use opal_core::{Color, Grid};

use crate::text::{indexed_color_to_rgb, TextRenderManager};
use wgpu::{CommandEncoder, Device, Queue, TextureView};

/// Renders terminal grid content using the text renderer
pub struct TerminalRenderer {
    text_renderer: TextRenderManager,
    char_width: f32,
    line_height: f32,
    padding_x: f32,
    padding_y: f32,
}

impl TerminalRenderer {
    pub fn new(device: &Device, queue: &Queue, format: wgpu::TextureFormat) -> Self {
        let text_renderer = TextRenderManager::new(device, queue, format);

        // Metrics for 14px monospace font
        let char_width = 8.4; // Approximate width for monospace
        let line_height = 20.0;

        Self {
            text_renderer,
            char_width,
            line_height,
            padding_x: 8.0,
            padding_y: 4.0,
        }
    }

    pub fn resize(&mut self, queue: &Queue, width: u32, height: u32) {
        self.text_renderer.resize(queue, width, height);
    }

    /// Render the terminal grid content
    pub fn render_grid(
        &mut self,
        device: &Device,
        queue: &Queue,
        encoder: &mut CommandEncoder,
        texture_view: &TextureView,
        grid: &Grid,
        cursor_visible: bool,
        cursor_row: usize,
        cursor_col: usize,
    ) -> anyhow::Result<()> {
        // For each row in the grid
        for row in 0..grid.rows() {
            // Collect cells into a string for the row
            let mut row_text = String::new();

            for col in 0..grid.cols() {
                if let Some(cell) = grid.get_cell(row, col) {
                    let cell_char = cell.c;

                    // Handle special characters
                    let display_char = if cell_char == '\0' || cell_char == ' ' {
                        ' '
                    } else {
                        cell_char
                    };

                    row_text.push(display_char);
                }
            }

            // Render the row text
            if !row_text.is_empty() {
                let y_offset = self.padding_y + row as f32 * self.line_height;

                self.text_renderer.render_terminal_line(
                    device,
                    queue,
                    &row_text,
                    row,
                    self.padding_x / self.char_width, // col_offset in chars
                    y_offset,
                    self.char_width,
                    self.line_height,
                );
            }
        }

        // Render the prepared text
        self.text_renderer
            .render(device, queue, encoder, texture_view)?;

        Ok(())
    }

    /// Calculate grid dimensions from window size
    pub fn calculate_grid_size(&self, width: u32, height: u32) -> (usize, usize) {
        let cols = ((width as f32 - 2.0 * self.padding_x) / self.char_width) as usize;
        let rows = ((height as f32 - 2.0 * self.padding_y) / self.line_height) as usize;
        (cols.max(1), rows.max(1))
    }

    /// Set font size and recalculate metrics
    pub fn set_font_size(&mut self, size: f32) {
        // Recalculate metrics based on font size
        // For monospace fonts, width is typically 0.6 * height
        self.char_width = size * 0.6;
        self.line_height = size * 1.4; // Line height is typically 1.4x font size
    }
}

/// Convert terminal Color to RGB values
fn terminal_color_to_rgb(color: &Color) -> [u8; 3] {
    match color {
        Color::Default => [255, 255, 255],
        Color::Indexed(idx) => indexed_color_to_rgb(*idx),
        Color::Rgb(r, g, b) => [*r, *g, *b],
    }
}
