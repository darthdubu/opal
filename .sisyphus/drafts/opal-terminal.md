# Draft: Opal Terminal

## Vision
A beautiful, lightning fast, thoughtful translucent terminal for macOS built in Rust, inspired by Apple's Liquid Glass design language.

## Core Principles (from user)
- **Beautiful**: Liquid Glass aesthetic, translucent, luminous
- **Lightning Fast**: Performance is paramount
- **Thoughtful**: Careful UX considerations
- **Platform**: macOS only (not iOS)

## Name
**Opal** - evokes the translucent, glowing quality of the design

## Open Questions
- Terminal emulation: VTE integration vs custom implementation?
- Rendering: GPU-accelerated (OpenGL/Vulkan/Metal) vs CPU?
- UI framework: Native AppKit bridge vs pure Rust (winit + custom)?
- Feature set: Minimal focused terminal vs full-featured (tabs, splits, etc.)?
- Configuration: File-based vs GUI preferences?
- Distribution: Homebrew, DMG, App Store?

## Technical Decisions CONFIRMED

### Rendering Backend
- **DECISION**: Metal (GPU-accelerated, native macOS)
- Rationale: Best performance on macOS, native blur effects, low latency

### UI Framework
- **DECISION**: AppKit bridge with Rust
- Rationale: Native macOS feel, best integration with system features
- Will use objc2 crate for Objective-C bridge

### Configuration
- **DECISION**: GUI preferences window (not file-based)
- Rationale: More accessible, modern macOS pattern

### Visual Design
- **DECISION**: Gentle blur effect (Liquid Glass aesthetic)
- Will use NSVisualEffectView or CALayer blur effects

### Features
- **DECISION**: Collapsible sidebar showing file directory
- Tree view of current working directory
- Collapsible (hide/show toggle)
- Updates as you cd around
- **Git integration** in sidebar: status indicators, branch switcher, useful git options
- **File actions**: Click opens in default editor (default: Micro, configurable)

## Feature Scope - CONFIRMED

### Target: Modern Essentials
- Tabs (Safari-style)
- Splits/panes (2-3 panes per window)
- Collapsible sidebar with file directory
- Themes and customization
- Keybindings configuration
- GUI preferences window
- NO plugin system (keep it focused)

### Terminal Emulation: Full Compatibility
- Full xterm/256-color/truecolor support
- tmux works perfectly
- All curses apps render correctly
- Legacy Unix app compatibility

### Timeline: Feature-Complete v1.0
- 6+ months timeline
- Production-ready daily driver
- Extensive testing and polish
- Ready to replace Terminal.app/iTerm2

### Architecture Overview
```
Opal Terminal (Rust + Metal + AppKit)
├── Core Terminal (CUSTOM BUILT - not alacritty_terminal)
│   ├── VTE Parser (escape sequence interpreter)
│   ├── Screen Buffer (scrollback, grid)
│   ├── Color System (256-color, truecolor)
│   └── State Machine (cursor, modes, attributes)
├── Metal Renderer (GPU-accelerated, custom shader for blur)
│   ├── Text Atlas (glyph caching)
│   ├── Composition (layers, effects)
│   └── Present (Metal command buffer)
├── AppKit UI Bridge (objc2 for native macOS integration)
│   ├── Main Window (NSWindow with NSVisualEffectView)
│   ├── Sidebar (File browser + Git integration, collapsible)
│   ├── Tab Bar (Safari-style tabs)
│   └── Preferences Window (GUI-based settings)
├── PTY Layer (Process spawning and I/O)
├── Git Integration (libgit2 or git2 crate)
├── Configuration System (GUI preferences, persisted)
└── Theme Engine (Liquid Glass + custom themes)
```

### Terminal Emulator: CUSTOM BUILT
- **DECISION**: Build terminal emulator from scratch (NOT using alacritty_terminal)
- **Rationale**: Opal should be unique, fully controlled, optimized for our specific use case
- **Scope**: VTE parser, screen buffer, color handling, cursor management, scrollback
- **Complexity**: High - requires deep terminal emulation knowledge
- **Trade-off**: Full control vs development time

### Test Strategy
- **DECISION**: Tests-After approach
- Implement features first, add tests after
- Balance of iteration speed and code quality

### File Editor Integration
- **Default editor**: Micro (terminal-based editor)
- **Configurable**: User can set any editor (vim, nano, VS Code, etc.)
- **Action**: Click file in sidebar → `$EDITOR <file>`

### Sidebar Git Features (Tasteful & Minimal)
- File status badges (modified ●, staged +, untracked ?, conflict ✗)
- Branch name in sidebar header with quick-switch dropdown
- Context menu: Stage, Unstage, Discard, Diff
- Recent commits list (collapsible)
- Clean visual design - information appears on demand

### Key Differentiators
1. **Liquid Glass aesthetic** - Gentle blur, translucency, depth
2. **Sidebar integration** - File browser that follows your cwd
3. **Metal rendering** - Native GPU acceleration
4. **GUI-first configuration** - No config files to edit
5. **macOS-native** - Feels like it belongs on macOS

## Distribution & Licensing - CONFIRMED

### License
- **DECISION**: Open Source (MIT or Apache 2.0)
- Community contributions welcome
- Full open source freedom

### Distribution Channel
- **Primary**: Homebrew (brew install opal)
- **Secondary**: Direct download (DMG from GitHub releases)

## Work Plan

### Wave 1: Foundation & Project Setup
- 1.1 Set up Rust project with Cargo.toml and dependencies
- 1.2 Configure objc2 bridge for AppKit integration
- 1.3 Set up Metal framework integration
- 1.4 Create project structure (modules, crates)
- 1.5 Add logging and error handling infrastructure
- 1.6 Verify empty shell builds successfully

### Wave 2: Custom Terminal Emulator Core
- 2.1 Design and implement VTE parser state machine
- 2.2 Implement escape sequence interpreter
- 2.3 Build screen buffer with scrollback (100k+ lines)
- 2.4 Implement 256-color and truecolor support
- 2.5 Implement cursor management and text attributes
- 2.6 Build PTY layer with process spawning
- 2.7 Implement input handling and terminal modes
- 2.8 Test terminal emulator with various apps

### Wave 3: Metal Rendering Engine
- 3.1 Set up Metal device, command queue, and pipeline
- 3.2 Implement text atlas with glyph caching
- 3.3 Build GPU-accelerated text renderer
- 3.4 Implement blur shader for Liquid Glass effect
- 3.5 Build composition pipeline
- 3.6 Implement vsync and frame pacing
- 3.7 Performance optimization

### Wave 4: AppKit UI Integration
- 4.1 Create main window with NSVisualEffectView blur
- 4.2 Implement window chrome and title bar
- 4.3 Build collapsible sidebar with file tree view
- 4.4 Implement Safari-style tab bar
- 4.5 Build tab/terminal pane management
- 4.6 Create GUI preferences window
- 4.7 Implement keyboard shortcut system
- 4.8 Add menu bar integration

### Wave 5: Sidebar Features & Git Integration
- 5.1 Implement file browser with tree view
- 5.2 Add cwd tracking and auto-refresh
- 5.3 Integrate git2 crate for Git operations
- 5.4 Implement file status indicators
- 5.5 Build branch switcher dropdown
- 5.6 Add context menu for git actions
- 5.7 Implement file click → open in editor
- 5.8 Add editor configuration in preferences

### Wave 6: Theme Engine & Polish
- 6.1 Build theme system with color schemes
- 6.2 Create default Liquid Glass theme
- 6.3 Add theme customization in preferences
- 6.4 Implement font selection and sizing
- 6.5 Add accessibility support
- 6.6 Performance profiling and optimization

### Wave 7: Testing & Release Preparation
- 7.1 Write integration tests for terminal emulator
- 7.2 Add UI tests for sidebar and preferences
- 7.3 Create test suite for Git integration
- 7.4 Set up CI/CD pipeline
- 7.5 Create Homebrew formula
- 7.6 Build DMG distribution package
- 7.7 Final QA and bug fixes
- 7.8 Prepare v1.0 release

## Research Pending
- [x] Rust terminal emulator landscape
- [x] Apple Liquid Glass design specifics
- [x] Rust macOS development patterns

## Current Research In Progress
**New questions for 2025 context:**
- [x] Liquid Glass design patterns for macOS (bg_2c5f97a4)
- [x] Rust+SwiftUI integration strategies (bg_2c9aae60)
- [x] Terminal emulator architecture landscape 2024 (bg_538e9227)

## 2025 Update - New Considerations
- SwiftUI improvements in macOS 15+
- Ghostty release (Mitchell Hashimoto's terminal)
- Rust+SwiftUI interop improvements

## Interview Questions (Current Session)
Verifying previous decisions and exploring SwiftUI vs AppKit choice given 2025 developments.


## Research Findings (2025)

### 1. Liquid Glass Design Language (macOS 26+/Tahoe)

**Key Discovery**: Liquid Glass is Apple's new design language introduced at WWDC 2025 for iOS 26, macOS Tahoe 26, etc.

**SwiftUI API** (available macOS 26+):
```swift
.glassEffect()                      // Basic glass
.glassEffect(.regular.interactive()) // Interactive glass
.glassEffect(.clear)                // High transparency
.buttonStyle(.glass)                // Glass button
.buttonStyle(.glassProminent)       // Primary glass button
```

**Alternative for pre-26 macOS**: Use NSVisualEffectView with .hudWindow material + custom Metal shaders

### 2. Terminal Emulator Architecture Landscape

**Current State (2024-2025)**:

Ghostty validates the Metal + SwiftUI architecture pattern - Core logic in Zig, platform UI in SwiftUI on macOS.

### 3. Rust + SwiftUI Integration Strategy

**Recommended Stack**:
- UniFFI + cargo-swift: Rust-Swift FFI binding
- wgpu: GPU abstraction with Metal backend
- glyphon: GPU text rendering
- vte: VT parser from Alacritty
- portable-pty: Cross-platform PTY

### 4. Metal vs OpenGL vs CoreText

**Metal (Recommended)**: Native Apple API, best performance on Apple Silicon, used by Ghostty successfully.

---

## Architecture Decision Update

Based on 2025 research, I recommend updating from AppKit+objc2 to SwiftUI+UniFFI+wgpu.

**Rationale**:
1. Ghostty validation: Proves Metal + SwiftUI is production-ready
2. Liquid Glass: SwiftUI has first-class .glassEffect() support
3. UniFFI maturity: Better than manual objc2 bridging
4. wgpu flexibility: Cross-platform while using Metal on macOS


## 🎨 Special Crates for Opal (Research Complete)

### Core Rendering Stack

| Crate | Purpose | Why It's Special |
|-------|---------|------------------|
| **wgpu** | GPU abstraction | Cross-platform, Metal backend, modern WebGPU API |
| **glyphon** | GPU text rendering | Built on wgpu, uses cosmic-text for shaping |
| **cosmic-text** | Text shaping | Advanced OpenType features, ligatures, emojis |
| **objc2-metal** | Metal bindings | Modern replacement for metal-rs, actively maintained |
| **UniFFI** + **cargo-swift** | Rust ↔ Swift | Auto-generates Swift bindings from Rust |

### The "Secret Sauce" Crates

#### 🎯 Typography & Visuals
- **swash** - Font introspection and high-quality rendering with OpenType feature control
- **kaku** - GPU text rendering with SDF (Signed Distance Field) support for resolution-independent fonts
- **auto-palette** - Extract dominant colors from images using DBSCAN/KMeans for dynamic theming
- **palette** - Color theory library with CIE CAM16 for generating harmonious themes

#### ⚡ Performance & UX
- **nucleo-matcher** - The fuzzy matching engine from Helix editor (faster than fzf/skim)
- **arboard** - Multi-format clipboard (images, RTF, HTML) - used by 1Password
- **eazy_tweener** - GSAP-like animations with 96 easing curves for smooth cursor/transitions
- **slotmap** - O(1) insert/delete with stable keys for efficient grid management

#### 🖼️ Advanced Features
- **par-term-emu-core-rust** - Recent crate with built-in Sixel/iTerm2/Kitty graphics protocols
- **accesskit** - Cross-platform accessibility infrastructure (make Opal the most accessible terminal!)
- **syntect** - Syntax highlighting for scrollback buffer ("smart cat")
- **notify-rust** - Native macOS notifications for long-running commands

### 🌟 Recommended "Wow Factor" Stack

```rust
// Cargo.toml for maximum specialness
[dependencies]
# Core
wgpu = "0.26"
glyphon = "0.6"
cosmic-text = "0.12"
vte = "0.15"
portable-pty = "0.9"

# SwiftUI Bridge
uniffi = "0.28"

# Visual Magic
auto-palette = "0.5"
palette = "0.7"
swash = "0.2"

# UX Enhancements
nucleo-matcher = "0.3"
arboard = "3.4"
eazy_tweener = "0.4"

# Accessibility
accesskit = "0.17"
```

---

## 🔮 Liquid Glass Shader Architecture

### Custom WGSL Shaders for Opal

Since we're using **wgpu**, we write shaders in **WGSL** (WebGPU Shading Language). Here's the architecture:

#### 1. Two-Pass Gaussian Blur (Foundation)
```wgsl
// Separable blur: O(n) instead of O(n²)
// Horizontal pass → Vertical pass
// At 1920x1080: ~0.5ms GPU time
```

#### 2. Frosted Glass Effect
- Blur background
- Add subtle noise pattern
- Edge highlighting for "light catching" effect

#### 3. Chromatic Aberration (Signature Effect)
- Split RGB channels at screen edges
- Subtle optical imperfection = premium feel
- Applied ONLY to background, not text

#### 4. Bloom/Glow
- Extract bright areas (cursor, selection)
- Blur and add back
- Makes cursor "glow"

### Performance Budget (60fps)

| Effect | GPU Time | Notes |
|--------|----------|-------|
| Text rendering | 1-2ms | GPU glyph sampling |
| Two-pass blur | 0.5ms | Separable Gaussian |
| Chromatic aberration | 0.1ms | 3 samples |
| Bloom | 0.4ms | 8-tap golden spiral |
| **Total** | **~2-4ms** | Well under 16ms budget |

### Hot-Reload for Shader Development

```rust
// Watch shader files and reload without restart
impl ShaderManager {
    pub fn check_for_reload(&mut self) -> bool {
        // File watcher triggers pipeline recreation
        // Instant feedback while tweaking glass effects
    }
}
```

---

## 🏗️ Final Architecture Recommendation

```
Opal Terminal
├── Rust Core (Performance Layer)
│   ├── wgpu Renderer (Metal backend)
│   │   ├── glyphon (text)
│   │   ├── Custom WGSL shaders (Liquid Glass)
│   │   └── Two-pass blur pipeline
│   ├── Terminal Emulator (vte parser)
│   ├── PTY Layer (portable-pty)
│   └── State Management (slotmap for grid)
├── SwiftUI UI (Native Layer)
│   ├── Main Window (.glassEffect)
│   ├── Sidebar (file browser)
│   ├── Tab Bar (Safari-style)
│   └── Preferences (GUI)
└── UniFFI Bridge (auto-generated)
    ├── Rust exports → Swift bindings
    └── Callbacks for events
```

### Why This Architecture Wins

1. **Ghostty-Validated**: Mitchell Hashimoto proved Zig + SwiftUI + Metal works at 44K stars
2. **Native Liquid Glass**: SwiftUI `.glassEffect()` on macOS 26+, custom shaders for older
3. **WGSL Shaders**: Write once, run on Metal (via wgpu) - no raw Metal needed
4. **Special Crates**: auto-palette, nucleo-matcher, syntect make Opal unique
5. **Performance**: 2-4ms for all effects leaves 12ms+ headroom for 60fps

---

## ✅ Decisions Summary

| Decision | Status | Notes |
|----------|--------|-------|
| **Language** | ✅ Rust + Swift | Core in Rust, UI in SwiftUI |
| **Renderer** | ✅ wgpu → Metal | Cross-platform, custom shaders |
| **UI** | ✅ SwiftUI | Native Liquid Glass effects |
| **Bridge** | ✅ UniFFI + cargo-swift | Auto-generated bindings |
| **Text** | ✅ glyphon + cosmic-text | Ligatures, GPU rendering |
| **Shaders** | ✅ Custom WGSL | Two-pass blur, chromatic aberration, bloom |
| **VTE** | ✅ vte crate | From Alacritty, proven fast |
| **PTY** | ✅ portable-pty | Wezterm's crate |
| **Special Features** | ✅ auto-palette, nucleo-matcher, syntect | Dynamic themes, fuzzy palette, syntax highlighting |

---

## 🚀 Ready for Plan Generation?

All research is complete. The architecture is:
- **Validated** by Ghostty's success
- **Modern** with wgpu + SwiftUI
- **Distinctive** with custom Liquid Glass shaders
- **Special** with unique crate choices

**Shall I generate the comprehensive work plan now?**

The plan will include:
- 7 parallel execution waves
- Specific crate choices for each wave
- Shader development strategy
- QA scenarios for each task
- 6-month timeline breakdown

