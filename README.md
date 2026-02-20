# Opal Terminal

A beautiful, lightning fast, thoughtful translucent terminal for macOS built in Rust, inspired by Apple's Liquid Glass design language.

## Features

- **Liquid Glass Design**: Gentle blur effects and translucency
- **Custom Terminal Emulator**: Built from scratch for optimal performance
- **File Sidebar**: Navigate your file system with ease
- **Git Integration**: See file status, branches, and perform git actions
- **Modern Tab System**: Safari-style tabs with keyboard shortcuts
- **GPU Accelerated**: Metal-based rendering for smooth performance

## Installation

### Homebrew

```bash
brew install opal
```

### Build from Source

```bash
git clone https://github.com/opal-terminal/opal.git
cd opal
cargo build --release
```

## Development

### Prerequisites

- Rust 1.70+
- macOS 12.0+
- Xcode Command Line Tools

### Building

```bash
cargo build
```

### Testing

```bash
cargo test
```

## Architecture

Opal consists of several key components:

- **Terminal Core**: Custom VTE parser, screen buffer with scrollback, PTY layer
- **Metal Renderer**: GPU-accelerated text rendering with glyph caching
- **UI Layer**: Tab management, sidebar, preferences
- **Git Integration**: File status, branch detection

## License

MIT OR Apache-2.0

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
