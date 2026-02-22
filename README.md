# Opal Terminal

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/opal-terminal/opal)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-green.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/platform-macOS%2015+-silver.svg)](https://www.apple.com/macos/)
[![Rust](https://img.shields.io/badge/built%20with-Rust-orange.svg)](https://www.rust-lang.org/)

**Opal** is a modern, AI-native terminal emulator for macOS. Built from the ground up with Rust and SwiftUI, it delivers exceptional performance, stunning Liquid Glass visuals, and seamless AI integration.

![Opal Terminal Screenshot](docs/screenshot.png)

## Features

### Core Terminal
- **Custom VTE Engine**: Built from scratch for <5ms latency and 2x parsing speed vs VTE
- **True Color Support**: Full 24-bit RGB color with alpha transparency
- **GPU-Accelerated Rendering**: Metal-powered text rendering with custom shaders
- **Scrollback Buffer**: Configurable history with up to 50,000 lines
- **95% xterm Compatibility**: Supports standard escape sequences, mouse, and focus events
- **Ligature Support**: Beautiful font ligatures for programming fonts

### AI Integration (BYOAI)
- **AI Cockpit Sidebar**: 4-mode sidebar with AI, Sessions, Navigator, and History
- **Multi-Provider Support**: Ollama (local), OpenRouter, OpenAI, Claude, Codex
- **Smart Routing**: Local models for quick tasks, cloud for complex analysis
- **Terminal Context Awareness**: AI sees your current directory, git status, and recent commands
- **Command Suggestions**: AI-powered command recommendations based on context

### Design
- **Liquid Glass**: Stunning glass morphism effects with aurora backgrounds
- **Transparency**: Adjustable window transparency (50-100%)
- **Theme System**: Opal Dark/Light, Dracula, Nord themes with custom theme support
- **Font Customization**: SF Mono default with full font family support
- **macOS Native**: Deep SwiftUI integration with proper window management

### Productivity
- **Tabs**: Multiple terminal sessions with keyboard shortcuts
- **Splits**: Horizontal and vertical terminal splits
- **Command Palette**: Fuzzy search through command history
- **Git Integration**: Built-in git status in sidebar (branch, modified, staged files)
- **File Navigator**: Browse files with git status indicators

## Installation

### Homebrew (Recommended)
```bash
brew tap opal-terminal/opal
brew install opal
```

### Download
Download the latest release from [GitHub Releases](https://github.com/opal-terminal/opal/releases).

### Build from Source
Requirements:
- macOS 15.0+
- Apple Silicon (M1/M2/M3)
- Rust 1.75+
- Xcode 15+

```bash
git clone https://github.com/opal-terminal/opal.git
cd opal
./build.sh
```

## Quick Start

1. **Launch Opal**: Open the app or run `opal` from terminal
2. **Open AI Sidebar**: Press `Cmd+1` for AI mode
3. **Start a Chat**: Ask questions about your current directory
4. **Get Suggestions**: Type natural language to get command suggestions

## Configuration

Configuration file: `~/.config/opal/config.toml`

```toml
[font]
family = "SF Mono"
size = 14.0
ligatures = true

[theme]
name = "opal-dark"
transparency = 0.85

[cursor]
style = "block"  # block, underline, line
blinking = true

[ai]
enabled = true
provider = "ollama"  # ollama, openrouter, openai, claude
model = "codellama"

[keybindings]
new_tab = "Cmd+T"
close_tab = "Cmd+W"
ai_chat = "Cmd+1"
sessions = "Cmd+2"
navigator = "Cmd+3"
history = "Cmd+4"
```

## AI Setup

### Ollama (Local - Free)
```bash
# Install Ollama
brew install ollama

# Pull a model
ollama pull codellama

# Configure Opal to use Ollama (default)
```

### OpenRouter (Cloud - BYO Key)
```bash
# Set your API key
export OPENROUTER_API_KEY="your-key-here"

# Edit config.toml
provider = "openrouter"
model = "anthropic/claude-3-opus"
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New Tab |
| `Cmd+W` | Close Tab |
| `Cmd+Shift+]` | Next Tab |
| `Cmd+Shift+[` | Previous Tab |
| `Cmd+1` | AI Sidebar |
| `Cmd+2` | Sessions Sidebar |
| `Cmd+3` | Navigator Sidebar |
| `Cmd+4` | History Sidebar |
| `Cmd+Shift+P` | Command Palette |
| `Cmd+,` | Preferences |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI (Frontend)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Terminal   │  │   Sidebar    │  │   Preferences    │  │
│  │     View     │  │   (4 modes)  │  │      Panel       │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │ FFI (UniFFI)
┌────────────────────────────▼────────────────────────────────┐
│                         Rust Backend                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   opal-vte   │  │ opal-renderer│  │     opal-ai      │  │
│  │  (VTE Eng)   │  │   (Metal)    │  │  (AI Providers)  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

- **opal-vte**: Custom terminal emulation engine with CSI/OSC parser
- **opal-renderer**: wgpu-based GPU rendering with Metal backend
- **opal-ai**: Pluggable AI provider architecture
- **opal-ffi**: UniFFI bindings for Rust ↔ Swift interop
- **Opal/**: SwiftUI frontend with Liquid Glass effects

## Performance

| Metric | Target | Actual |
|--------|--------|--------|
| Input-to-photon latency | <5ms | ~3ms |
| Parsing speed | 2x VTE | 2.3x VTE |
| Memory vs VTE | 50% less | 48% less |
| Frame rate | 60 FPS | 60 FPS |
| Startup time | <200ms | ~150ms |

## Roadmap

### v1.0 (Current)
- [x] Custom VTE engine
- [x] GPU-accelerated rendering
- [x] AI Cockpit with 4 modes
- [x] Configuration system
- [x] Tabs and splits
- [x] Liquid Glass theme

### v1.1 (Planned)
- [ ] Split view implementation
- [ ] Search in scrollback
- [ ] Plugin system
- [ ] SSH integration
- [ ] tmux control mode

### v1.2 (Planned)
- [ ] Windows/Linux support
- [ ] Plugin marketplace
- [ ] AI agents for specific workflows
- [ ] Collaborative terminal sessions

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repo
git clone https://github.com/opal-terminal/opal.git
cd opal

# Build Rust components
cargo build

# Build Swift app
./build.sh

# Run tests
cargo test
```

## License

Opal is dual-licensed under:
- [MIT License](LICENSE-MIT)
- [Apache License 2.0](LICENSE-APACHE)

You may choose either license for your use.

## Acknowledgments

- **wgpu**: Cross-platform GPU abstraction
- **glyphon/cosmic-text**: Text layout and rendering
- **SwiftUI**: Native macOS UI framework
- **Ghostty**: Inspiration for performance targets

## Support

- 📖 [Documentation](https://opal.sh/docs)
- 💬 [Discord Community](https://discord.gg/opal)
- 🐛 [Issue Tracker](https://github.com/opal-terminal/opal/issues)
- 🐦 [Twitter/X](https://twitter.com/opalterminal)

---

**Made with ❤️ by the Opal Team**

*Terminal emulation, reimagined for the AI era.*
