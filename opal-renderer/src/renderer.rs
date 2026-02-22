use wgpu::{Device, Queue, Surface, SurfaceConfiguration, RenderPipeline, PipelineLayout, ShaderModule, Buffer, BindGroup};
use std::sync::Arc;
use crate::terminal_renderer::TerminalRenderer;
use crate::text::TextRenderManager;
use opal_core::{Grid, Cursor};

/// Complete terminal renderer with Metal backend
pub struct Renderer {
    device: Arc<Device>,
    queue: Arc<Queue>,
    surface: Surface<'static>,
    config: SurfaceConfiguration,
    terminal_renderer: TerminalRenderer,
    cell_pipeline: RenderPipeline,
    cursor_pipeline: RenderPipeline,
    background_pipeline: RenderPipeline,
    cell_bind_group: BindGroup,
    cursor_bind_group: BindGroup,
    background_bind_group: BindGroup,
}

impl Renderer {
    pub async fn new(window: Arc<winit::window::Window>) -> anyhow::Result<Self> {
        let instance = wgpu::Instance::new(&wgpu::InstanceDescriptor {
            backends: wgpu::Backends::METAL,
            ..Default::default()
        });

        let surface = instance.create_surface(window.clone())?;

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            })
            .await?;

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    label: Some("Opal Device"),
                    required_features: wgpu::Features::empty(),
                    required_limits: wgpu::Limits::default(),
                    memory_hints: wgpu::MemoryHints::Performance,
                    experimental_features: wgpu::ExperimentalFeatures::disabled(),
                    trace: wgpu::Trace::Off,
                },
            )
            .await?;

        let surface_caps = surface.get_capabilities(&adapter);
        let surface_format = surface_caps
            .formats
            .iter()
            .copied()
            .find(|f| f.is_srgb())
            .unwrap_or(surface_caps.formats[0]);

        let size = window.inner_size();
        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface_format,
            width: size.width,
            height: size.height,
            present_mode: wgpu::PresentMode::Fifo,
            alpha_mode: wgpu::CompositeAlphaMode::PostMultiplied,
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };

        surface.configure(&device, &config);

        let device = Arc::new(device);
        let queue = Arc::new(queue);

        // Initialize terminal renderer
        let terminal_renderer = TerminalRenderer::new(&device, &queue, surface_format);

        // Create render pipelines
        let cell_pipeline = Self::create_cell_pipeline(&device, surface_format);
        let cursor_pipeline = Self::create_cursor_pipeline(&device, surface_format);
        let background_pipeline = Self::create_background_pipeline(&device, surface_format);

        // Create bind groups
        let cell_bind_group = Self::create_cell_bind_group(&device);
        let cursor_bind_group = Self::create_cursor_bind_group(&device);
        let background_bind_group = Self::create_background_bind_group(&device);

        Ok(Self {
            device,
            queue,
            surface,
            config,
            terminal_renderer,
            cell_pipeline,
            cursor_pipeline,
            background_pipeline,
            cell_bind_group,
            cursor_bind_group,
            background_bind_group,
        })
    }

    /// Main render method - renders terminal content
    pub fn render(
        &mut self,
        grid: &Grid,
        cursor: &Cursor,
        cursor_visible: bool,
    ) -> anyhow::Result<()> {
        let output = self.surface.get_current_texture()?;
        let view = output.texture.create_view(&wgpu::TextureViewDescriptor::default());

        let mut encoder = self.device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: Some("Render Encoder"),
        });

        // Render background with glass effect
        self.render_background(&mut encoder, &view);

        // Render terminal grid content
        self.render_grid(&mut encoder, &view, grid, cursor, cursor_visible)?;

        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();

        Ok(())
    }

    fn render_background(
        &self,
        encoder: &mut wgpu::CommandEncoder,
        view: &wgpu::TextureView,
    ) {
        let _render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("Background Pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color {
                        r: 0.0,
                        g: 0.0,
                        b: 0.0,
                        a: 0.85, // Transparent background
                    }),
                    store: wgpu::StoreOp::Store,
                },
                depth_slice: None,
            })],
            depth_stencil_attachment: None,
            timestamp_writes: None,
            occlusion_query_set: None,
            multiview_mask: None,
        });
    }

    fn render_grid(
        &mut self,
        encoder: &mut wgpu::CommandEncoder,
        view: &wgpu::TextureView,
        grid: &Grid,
        cursor: &Cursor,
        cursor_visible: bool,
    ) -> anyhow::Result<()> {
        // Render terminal content using the terminal renderer
        self.terminal_renderer.render_grid(
            &self.device,
            &self.queue,
            encoder,
            view,
            grid,
            cursor_visible,
            cursor.row,
            cursor.col,
        )?;

        // Render cursor if visible
        if cursor_visible {
            self.render_cursor(encoder, view, cursor, grid);
        }

        Ok(())
    }

    fn render_cursor(
        &self,
        encoder: &mut wgpu::CommandEncoder,
        view: &wgpu::TextureView,
        cursor: &Cursor,
        grid: &Grid,
    ) {
        let _render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("Cursor Pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Load,
                    store: wgpu::StoreOp::Store,
                },
                depth_slice: None,
            })],
            depth_stencil_attachment: None,
            timestamp_writes: None,
            occlusion_query_set: None,
            multiview_mask: None,
        });

        // Cursor rendering is handled by the terminal renderer
        // This is a placeholder for additional cursor effects
    }

    pub fn resize(&mut self, width: u32, height: u32) {
        if width > 0 && height > 0 {
            self.config.width = width;
            self.config.height = height;
            self.surface.configure(&self.device, &self.config);
            self.terminal_renderer.resize(&self.queue, width, height);
        }
    }

    /// Calculate grid dimensions from window size
    pub fn calculate_grid_size(&self, width: u32, height: u32) -> (usize, usize) {
        self.terminal_renderer.calculate_grid_size(width, height)
    }

    fn create_cell_pipeline(device: &Device, format: wgpu::TextureFormat) -> RenderPipeline {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Cell Shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/cell.wgsl").into()),
        });

        let layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Cell Pipeline Layout"),
            bind_group_layouts: &[],
            immediate_size: 0,
            
            
        });

        device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Cell Pipeline"),
            layout: Some(&layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format,
                    blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: Default::default(),
            }),
            primitive: wgpu::PrimitiveState::default(),
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview_mask: None,
            cache: None,
        })
    }

    fn create_cursor_pipeline(device: &Device, format: wgpu::TextureFormat) -> RenderPipeline {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Cursor Shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/cursor.wgsl").into()),
        });

        let layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Cursor Pipeline Layout"),
            bind_group_layouts: &[],
            immediate_size: 0,
            
            
        });

        device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Cursor Pipeline"),
            layout: Some(&layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format,
                    blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: Default::default(),
            }),
            primitive: wgpu::PrimitiveState::default(),
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview_mask: None,
            cache: None,
        })
    }

    fn create_background_pipeline(device: &Device, format: wgpu::TextureFormat) -> RenderPipeline {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Background Shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/liquid_glass.wgsl").into()),
        });

        let layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("Background Pipeline Layout"),
            bind_group_layouts: &[],
            immediate_size: 0,
            
            
        });

        device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Background Pipeline"),
            layout: Some(&layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format,
                    blend: Some(wgpu::BlendState::ALPHA_BLENDING),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: Default::default(),
            }),
            primitive: wgpu::PrimitiveState::default(),
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview_mask: None,
            cache: None,
        })
    }

    fn create_cell_bind_group(device: &Device) -> BindGroup {
        let layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("Cell Bind Group Layout"),
            entries: &[],
        });

        device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("Cell Bind Group"),
            layout: &layout,
            entries: &[],
        })
    }

    fn create_cursor_bind_group(device: &Device) -> BindGroup {
        let layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("Cursor Bind Group Layout"),
            entries: &[],
        });

        device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("Cursor Bind Group"),
            layout: &layout,
            entries: &[],
        })
    }

    fn create_background_bind_group(device: &Device) -> BindGroup {
        let layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("Background Bind Group Layout"),
            entries: &[],
        });

        device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("Background Bind Group"),
            layout: &layout,
            entries: &[],
        })
    }
}
