# Opal Terminal Work Plan

## TL;DR

> **Quick Summary**: Build a beautiful, GPU-accelerated macOS terminal with Liquid Glass aesthetic using Rust + SwiftUI + wgpu. Features custom WGSL shaders (blur, chromatic aberration, bloom), dynamic themes from wallpapers, fuzzy command palette, and accessibility-first design.
>
> **Deliverables**:
> - Production-ready terminal emulator (v1.0)
> - Custom VTE parser with full xterm compatibility
> - wgpu-based renderer with Liquid Glass shaders
> - SwiftUI native UI with tabs, sidebar, and preferences
> - Homebrew distribution
>
> **Estimated Effort**: Large (6+ months)
> **Parallel Execution**: YES - 7 waves with 5-8 tasks each
> **Critical Path**: Foundation → VTE Core → Renderer → SwiftUI Bridge → Sidebar → Polish → Release

---

## Context

### Original Request
Build Opal - a native macOS terminal using Metal rendering with Liquid Glass design language. Rust for performance, SwiftUI for native UI. Blazing fast, gorgeous, lean with translucent blur effects.

### Interview Summary
**Key Discussions**:
- Architecture: Rust core + SwiftUI (Ghostty-validated pattern)
- Rendering: wgpu → Metal with custom WGSL shaders
- Shaders: Two-pass blur, chromatic aberration, bloom
- VTE: Building custom from scratch (not using alacritty_terminal)
- Features: Tabs, splits, sidebar with git, fuzzy palette, dynamic themes

**Research Findings**:
- Ghostty proves Rust/Zig + SwiftUI + Metal works at 44K stars
- Liquid Glass: SwiftUI `.glassEffect()` API in macOS 26+
- Special crates: auto-palette, nucleo-matcher, syntect for differentiation
- Performance: 2-4ms GPU budget for all effects

### Technical Stack Confirmed
| Component | Choice |
|-----------|--------|
| Language | Rust + Swift |
| Renderer | wgpu → Metal |
| UI | SwiftUI |
| Bridge | UniFFI + cargo-swift |
| Text | glyphon + cosmic-text |
| VTE | vte crate (custom build) |
| PTY | portable-pty |

---

## Work Objectives

### Core Objective
Build Opal Terminal - a production-ready, GPU-accelerated macOS terminal with distinctive Liquid Glass aesthetic, full xterm compatibility, and unique features like dynamic wallpaper-based themes and fuzzy command palette.

### Concrete Deliverables
1. **Rust Core Library**: Terminal emulator, PTY, renderer
2. **SwiftUI App**: Native macOS UI with tabs, sidebar, preferences
3. **WGSL Shaders**: Two-pass blur, chromatic aberration, bloom
4. **Distribution**: Homebrew formula + GitHub releases

### Definition of Done
- [ ] Renders all common terminal apps correctly (vim, tmux, htop)
- [ ] 60fps with all shader effects enabled
- [ ] Passes terminal compatibility test suite
- [ ] Homebrew installable
- [ ] Accessibility certified (VoiceOver compatible)

### Must Have
- Custom VTE parser with full escape sequence support
- GPU-accelerated text rendering with ligatures
- Liquid Glass shaders (blur, chromatic aberration, bloom)
- Tabs and splits
- Sidebar with file browser and git integration
- Fuzzy command palette
- Dynamic themes from wallpaper
- Syntax highlighting in scrollback
- Accessibility support

### Must NOT Have (Guardrails)
- Plugin system (keep focused)
- Windows/Linux support (macOS only for v1.0)
- Built-in multiplexer (tmux works, don't compete)
- Plugin API

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO (need to set up)
- **Automated tests**: Tests-After (implement first, test after)
- **Framework**: cargo test + custom terminal test suite

### QA Policy
Every task includes agent-executed QA scenarios:
- **Frontend/UI**: Playwright screenshots and assertions
- **Terminal**: Automated PTY interaction tests
- **Performance**: FPS benchmarks
- **Build**: CI verification

### Evidence Path
All QA evidence saved to `.sisyphus/evidence/task-{N}-{scenario}.{ext}`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1: Foundation (Weeks 1-2)
├── Rust project setup with Cargo.toml
├── UniFFI + cargo-swift configuration
├── wgpu initialization
├── Basic project structure
└── CI/CD pipeline setup

Wave 2: VTE Core (Weeks 3-6)
├── VTE parser state machine
├── Escape sequence interpreter
├── Screen buffer with scrollback
├── Color system (256-color, truecolor)
├── PTY layer integration
└── Basic terminal functionality tests

Wave 3: Renderer (Weeks 7-10)
├── wgpu pipeline setup
├── glyphon text rendering
├── Glyph atlas caching
├── Basic shader pipeline
└── Performance baseline

Wave 4: Liquid Glass Shaders (Weeks 11-13)
├── Two-pass Gaussian blur
├── Frosted glass effect
├── Chromatic aberration
├── Bloom/glow effects
├── Shader hot-reload system
└── Performance optimization

Wave 5: SwiftUI Bridge (Weeks 14-16)
├── UniFFI bindings generation
├── SwiftUI window integration
├── Tab bar implementation
├── Sidebar file browser
└── Preferences window

Wave 6: Features & Polish (Weeks 17-20)
├── Git integration in sidebar
├── Fuzzy command palette (nucleo-matcher)
├── Dynamic themes (auto-palette)
├── Syntax highlighting (syntect)
├── Accessibility (accesskit)
└── Animation system (eazy_tweener)

Wave 7: Release (Weeks 21-24)
├── Integration testing
├── Performance profiling
├── Homebrew formula
├── DMG packaging
├── Documentation
└── v1.0 release
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|------------|--------|
| 1.1-1.5 | - | All |
| 2.1 VTE Parser | 1.x | 2.2-2.8 |
| 2.8 PTY | 1.x | 3.x |
| 3.1 wgpu Setup | 1.x | 3.2-3.5 |
| 3.5 Renderer | 3.1-3.4 | 4.x, 5.x |
| 4.x Shaders | 3.5 | 6.5 Animation |
| 5.x SwiftUI | 1.2 UniFFI, 3.5 Renderer | 6.x |
| 6.x Features | 5.x | 7.x |
| 7.x Release | All above | - |

### Critical Path
Foundation (1.x) → VTE Parser (2.1) → Screen Buffer (2.3) → Renderer (3.5) → SwiftUI Bridge (5.1) → Features (6.x) → Release (7.x)

---

## TODOs

### Wave 1: Foundation (Weeks 1-2)

- [ ] 1.1 Set up Rust project structure

  **What to do**:
  - Create workspace with crates: `opal-core`, `opal-renderer`, `opal-ffi`
  - Set up Cargo.toml with core dependencies
  - Add rust-toolchain.toml for consistent Rust version
  - Configure cargo workspace members

  **Must NOT do**:
  - Don't add all dependencies at once
  - Don't create complex build scripts yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: None needed
  - **Rationale**: Simple project scaffolding

  **Parallelization**:
  - **Can Run In Parallel**: YES - Wave 1 tasks
  - **Blocks**: 1.2, 1.3
  - **Blocked By**: None

  **References**:
  - Ghostty's repo structure: https://github.com/ghostty-org/ghostty
  - Rust workspace guide: https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html

  **Acceptance Criteria**:
  - [ ] `cargo check` passes in all crates
  - [ ] Workspace builds successfully
  - [ ] Directory structure matches architecture plan

  **QA Scenarios**:
  ```
  Scenario: Project builds
    Tool: Bash
    Steps:
      1. Run `cargo check --all`
      2. Run `cargo build --all`
    Expected Result: Both commands succeed with no errors
    Evidence: .sisyphus/evidence/task-1-1-build.txt
  ```

  **Commit**: YES
  - Message: `chore(project): initial workspace structure`
  - Files: `Cargo.toml`, `*/Cargo.toml`, `.gitignore`

- [ ] 1.2 Configure UniFFI and cargo-swift

  **What to do**:
  - Install cargo-swift: `cargo install cargo-swift`
  - Create UDL file for FFI interface definitions
  - Set up UniFFI scaffolding in `opal-ffi` crate
  - Create initial Swift bindings test
  - Configure XCFramework generation

  **Must NOT do**:
  - Don't expose complex types initially
  - Don't worry about callback design yet

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: FFI configuration requires understanding of both Rust and Swift

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 1.1
  - **Blocks**: 1.3, 5.x
  - **Blocked By**: 1.1

  **References**:
  - UniFFI guide: https://mozilla.github.io/uniffi-rs/
  - cargo-swift: https://github.com/antoniusnaumann/cargo-swift
  - Example: https://github.com/mozilla/uniffi-rs/tree/main/examples

  **Acceptance Criteria**:
  - [ ] `cargo swift package` generates XCFramework
  - [ ] Swift can call simple Rust function
  - [ ] UDL file compiles without errors

  **QA Scenarios**:
  ```
  Scenario: FFI bridge works
    Tool: Bash
    Steps:
      1. Run `cargo swift package`
      2. Check `opal-ffi/swift/` exists with generated bindings
      3. Verify XCFramework builds
    Expected Result: XCFramework created, bindings generated
    Evidence: .sisyphus/evidence/task-1-2-ffi.txt
  ```

  **Commit**: YES
  - Message: `feat(ffi): setup uniffi and cargo-swift`
  - Files: `opal-ffi/`, `*.udl`, `Package.swift`

- [ ] 1.3 Initialize wgpu and create basic window

  **What to do**:
  - Add wgpu dependency to `opal-renderer`
  - Create basic wgpu instance and surface
  - Initialize Metal backend on macOS
  - Create swap chain configuration
  - Set up basic render loop structure

  **Must NOT do**:
  - Don't implement text rendering yet
  - Don't worry about shaders yet

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: GPU initialization requires careful error handling

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 1.1, 1.2
  - **Blocks**: 3.x
  - **Blocked By**: 1.1

  **References**:
  - wgpu hello-triangle: https://github.com/gfx-rs/wgpu/tree/trunk/examples
  - Learn Wgpu: https://sotrh.github.io/learn-wgpu/
  - wgpu on macOS: https://docs.rs/wgpu/latest/wgpu/

  **Acceptance Criteria**:
  - [ ] wgpu instance creates successfully
  - [ ] Metal backend selected on macOS
  - [ ] Surface creation works
  - [ ] Basic render loop runs without crash

  **QA Scenarios**:
  ```
  Scenario: wgpu initializes
    Tool: Bash
    Steps:
      1. Run `cargo test -p opal-renderer --test wgpu_init`
    Expected Result: Test passes, Metal backend detected
    Evidence: .sisyphus/evidence/task-1-3-wgpu.txt
  ```

  **Commit**: YES
  - Message: `feat(renderer): initialize wgpu with metal backend`
  - Files: `opal-renderer/src/lib.rs`, `opal-renderer/tests/`

- [ ] 1.4 Set up CI/CD pipeline

  **What to do**:
  - Create `.github/workflows/ci.yml`
  - Set up Rust build matrix (stable, nightly)
  - Configure clippy and fmt checks
  - Set up dependency caching
  - Add basic test execution

  **Must NOT do**:
  - Don't add Swift build yet (too early)
  - Don't add release automation yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: None needed
  - **Rationale**: Standard CI setup

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 1.1-1.3
  - **Blocks**: All subsequent tasks (for CI)
  - **Blocked By**: 1.1

  **References**:
  - GitHub Actions Rust: https://github.com/actions-rs
  - Rust CI template: https://github.com/actions-rs/meta

  **Acceptance Criteria**:
  - [ ] CI runs on push and PR
  - [ ] Build passes
  - [ ] Clippy warnings fail build
  - [ ] Tests execute

  **QA Scenarios**:
  ```
  Scenario: CI passes
    Tool: GitHub Actions
    Steps:
      1. Push commit
      2. Wait for CI
    Expected Result: All checks green
    Evidence: CI run link in PR
  ```

  **Commit**: YES
  - Message: `ci: setup github actions workflow`
  - Files: `.github/workflows/ci.yml`

- [ ] 1.5 Add logging and error handling infrastructure

  **What to do**:
  - Add `tracing` for structured logging
  - Configure `color-eyre` for better error reports
  - Set up log levels and filtering
  - Create error type hierarchy
  - Add panic handler with helpful messages

  **Must NOT do**:
  - Don't over-engineer error types
  - Don't add file logging yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: None needed
  - **Rationale**: Infrastructure setup

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 1.1-1.4
  - **Blocks**: 2.x, 3.x
  - **Blocked By**: 1.1

  **References**:
  - tracing: https://docs.rs/tracing/latest/tracing/
  - color-eyre: https://docs.rs/color-eyre/latest/color_eyre/

  **Acceptance Criteria**:
  - [ ] `tracing` works across all crates
  - [ ] Errors display with backtraces
  - [ ] Panic handler installed

  **QA Scenarios**:
  ```
  Scenario: Logging works
    Tool: Bash
    Steps:
      1. Run app with RUST_LOG=debug
      2. Check logs appear
    Expected Result: Structured logs visible
    Evidence: .sisyphus/evidence/task-1-5-logging.txt
  ```

  **Commit**: YES
  - Message: `feat(infra): add tracing and error handling`
  - Files: `opal-core/src/logging.rs`, `opal-core/src/error.rs`

### Wave 2: VTE Core (Weeks 3-6)

- [ ] 2.1 Design VTE parser state machine

  **What to do**:
  - Study vte crate architecture from Alacritty
  - Design state machine for escape sequence parsing
  - Define parser states: Ground, Escape, CSI, OSC, etc.
  - Create trait for handling parser events
  - Implement basic state transitions

  **Must NOT do**:
  - Don't implement all escape sequences yet
  - Don't worry about performance optimization yet

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: None needed
  - **Rationale**: Complex state machine design

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 2.2
  - **Blocks**: 2.3-2.8
  - **Blocked By**: 1.x

  **References**:
  - vte crate: https://docs.rs/vte/latest/vte/
  - VT100 terminal codes: https://vt100.net/docs/vt100-ug/chapter3.html
  - XTerm control sequences: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html

  **Acceptance Criteria**:
  - [ ] State machine compiles
  - [ ] Basic transitions work (Ground → Escape → Ground)
  - [ ] Trait defined for event handlers

  **QA Scenarios**:
  ```
  Scenario: Parser state transitions
    Tool: cargo test
    Steps:
      1. Test Ground → Escape transition
      2. Test Escape → CSI transition
      3. Test CSI parameter parsing
    Expected Result: All state transitions correct
    Evidence: .sisyphus/evidence/task-2-1-parser.txt
  ```

  **Commit**: YES
  - Message: `feat(vte): design parser state machine`
  - Files: `opal-core/src/vte/`

- [ ] 2.2 Implement escape sequence interpreter

  **What to do**:
  - Implement CSI (Control Sequence Introducer) handlers
  - Support cursor movement: CUU, CUD, CUF, CUB, CUP
  - Support erase: ED, EL
  - Support SGR (Select Graphic Rendition) for colors
  - Handle OSC 133 for shell integration

  **Must NOT do**:
  - Don't implement all 500+ escape sequences
  - Focus on most common ones first

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: Many escape sequences to implement

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 2.1
  - **Blocks**: 2.3
  - **Blocked By**: 1.x

  **References**:
  - XTerm control sequences: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
  - OSC 133 spec: https://gitlab.freedesktop.org/utf/utf/-/wikis/Proposals/semantic-prompts

  **Acceptance Criteria**:
  - [ ] Cursor movement sequences work
  - [ ] Color sequences work
  - [ ] Clear screen works
  - [ ] OSC 133 marks detected

  **QA Scenarios**:
  ```
  Scenario: Common escape sequences
    Tool: cargo test
    Steps:
      1. Test \x1b[2J (clear screen)
      2. Test \x1b[31m (red text)
      3. Test \x1b[H (cursor home)
    Expected Result: All sequences parsed correctly
    Evidence: .sisyphus/evidence/task-2-2-escapes.txt
  ```

  **Commit**: YES
  - Message: `feat(vte): implement common escape sequences`
  - Files: `opal-core/src/vte/`

- [ ] 2.3 Build screen buffer with scrollback

  **What to do**:
  - Implement 2D grid of cells (row x column)
  - Each cell: char, fg color, bg color, attributes (bold, italic, etc.)
  - Scrollback buffer: ring buffer of lines
  - Support 100k+ lines of scrollback
  - Optimize for sparse updates

  **Must NOT do**:
  - Don't use naive Vec<Vec<Cell>> (cache inefficient)
  - Don't store full scrollback in GPU memory

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: None needed
  - **Rationale**: Performance-critical data structure

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: 2.4, 3.x
  - **Blocked By**: 2.1, 2.2

  **References**:
  - Alacritty's grid: https://github.com/alacritty/vte/blob/master/src/grid.rs
  - Slotmap for cell storage: https://docs.rs/slotmap/latest/slotmap/

  **Acceptance Criteria**:
  - [ ] Grid stores cells correctly
  - [ ] Scrollback works (100k lines)
  - [ ] Resizing preserves content
  - [ ] Memory usage reasonable (<100MB for 100k lines)

  **QA Scenarios**:
  ```
  Scenario: Scrollback buffer
    Tool: cargo test
    Steps:
      1. Fill buffer with 100k lines
      2. Scroll up and down
      3. Resize grid
    Expected Result: No crashes, content preserved
    Evidence: .sisyphus/evidence/task-2-3-scrollback.txt
  ```

  **Commit**: YES
  - Message: `feat(vte): implement screen buffer with scrollback`
  - Files: `opal-core/src/grid.rs`

- [ ] 2.4 Implement 256-color and truecolor support

  **What to do**:
  - Parse SGR sequences for 256-color palette
  - Support 24-bit RGB truecolor (\x1b[38;2;R;G;Bm)
  - Create color conversion utilities
  - Handle color approximations if needed

  **Must NOT do**:
  - Don't worry about color themes yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: None needed
  - **Rationale**: Straightforward implementation

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 2.3
  - **Blocks**: 3.x
  - **Blocked By**: 2.2

  **References**:
  - 256 colors: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
  - Truecolor: https://github.com/termstandard/colors

  **Acceptance Criteria**:
  - [ ] 256-color sequences work
  - [ ] Truecolor RGB works
  - [ ] Color values stored correctly in cells

  **QA Scenarios**:
  ```
  Scenario: Color support
    Tool: cargo test
    Steps:
      1. Test 256-color: \x1b[38;5;196m
      2. Test truecolor: \x1b[38;2;255;0;0m
    Expected Result: Correct RGB values in cells
    Evidence: .sisyphus/evidence/task-2-4-colors.txt
  ```

  **Commit**: YES
  - Message: `feat(vte): add 256-color and truecolor support`
  - Files: `opal-core/src/color.rs`

- [ ] 2.5 Implement cursor management and text attributes

  **What to do**:
  - Track cursor position (x, y)
  - Handle cursor visibility (DECTCEM)
  - Support text attributes: bold, italic, underline, strikethrough
  - Handle cursor styles (block, line, bar)
  - Blinking cursor support

  **Must NOT do**:
  - Don't implement advanced cursor features yet (focus events)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: Multiple attributes to track

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 2.3, 2.4
  - **Blocks**: 2.6
  - **Blocked By**: 2.2

  **References**:
  - Cursor control: https://vt100.net/docs/vt510-rm/DECTCEM.html

  **Acceptance Criteria**:
  - [ ] Cursor position tracked correctly
  - [ ] Text attributes applied to cells
  - [ ] Cursor visibility toggle works

  **QA Scenarios**:
  ```
  Scenario: Cursor and attributes
    Tool: cargo test
    Steps:
      1. Move cursor with CUP
      2. Write text with bold attribute
      3. Toggle cursor visibility
    Expected Result: Cursor position correct, attributes set
    Evidence: .sisyphus/evidence/task-2-5-cursor.txt
  ```

  **Commit**: YES
  - Message: `feat(vte): implement cursor and text attributes`
  - Files: `opal-core/src/cursor.rs`

- [ ] 2.6 Build PTY layer with process spawning

  **What to do**:
  - Integrate portable-pty crate
  - Spawn shell process (bash, zsh, fish)
  - Read/write to PTY master
  - Handle process exit
  - Support shell environment variables

  **Must NOT do**:
  - Don't implement session restoration yet

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: PTY handling can be tricky

  **Parallelization**:
  - **Can Run In Parallel**: YES - with 2.3-2.5
  - **Blocks**: 2.7
  - **Blocked By**: 1.x

  **References**:
  - portable-pty: https://docs.rs/portable-pty/latest/portable_pty/
  - PTY overview: https://en.wikipedia.org/wiki/Pseudoterminal

  **Acceptance Criteria**:
  - [ ] Shell spawns successfully
  - [ ] Can write commands to PTY
  - [ ] Can read output from PTY
  - [ ] Process exit detected

  **QA Scenarios**:
  ```
  Scenario: PTY works
    Tool: cargo test --ignored
    Steps:
      1. Spawn /bin/echo
      2. Write "hello"
      3. Read output
      4. Wait for exit
    Expected Result: Output matches "hello\n"
    Evidence: .sisyphus/evidence/task-2-6-pty.txt
  ```

  **Commit**: YES
  - Message: `feat(pty): integrate portable-pty for process spawning`
  - Files: `opal-core/src/pty.rs`

- [ ] 2.7 Implement input handling and terminal modes

  **What to do**:
  - Handle keyboard input (send to PTY)
  - Support special keys: arrows, function keys, ctrl combinations
  - Implement terminal modes: canonical/raw
  - Handle alt/option key properly
  - Mouse support (optional for now)

  **Must NOT do**:
  - Don't implement all terminal modes (focus on common ones)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: Input handling is complex

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: 2.8
  - **Blocked By**: 2.6

  **References**:
  - Input sequences: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-PC-Style-Function-Keys

  **Acceptance Criteria**:
  - [ ] Typing sends characters to PTY
  - [ ] Arrow keys send escape sequences
  - [ ] Ctrl+C sends SIGINT
  - [ ] Special keys work (Enter, Backspace, Tab)

  **QA Scenarios**:
  ```
  Scenario: Input handling
    Tool: cargo test
    Steps:
      1. Send 'a' character
      2. Send arrow key
      3. Send Ctrl+C
    Expected Result: Correct bytes sent to PTY
    Evidence: .sisyphus/evidence/task-2-7-input.txt
  ```

  **Commit**: YES
  - Message: `feat(input): implement keyboard input handling`
  - Files: `opal-core/src/input.rs`

- [ ] 2.8 Test terminal emulator with various apps

  **What to do**:
  - Test with simple commands: ls, cat, echo
  - Test with vim (basic editing)
  - Test with htop
  - Test color output
  - Verify no crashes or garbled output

  **Must NOT do**:
  - Don't test complex apps yet (tmux can wait)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: None needed
  - **Rationale**: Integration testing

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: 3.x
  - **Blocked By**: 2.1-2.7

  **Acceptance Criteria**:
  - [ ] ls shows files
  - [ ] vim opens and edits
  - [ ] htop displays
  - [ ] Colors render correctly

  **QA Scenarios**:
  ```
  Scenario: Terminal works
    Tool: Manual test
    Steps:
      1. Run terminal
      2. Type 'ls -la'
      3. Type 'vim test.txt'
    Expected Result: Apps display correctly
    Evidence: Screenshot in .sisyphus/evidence/task-2-8-terminal.png
  ```

  **Commit**: YES
  - Message: `test(vte): verify terminal with real applications`
  - Files: Test results documented

---

## Final Verification Wave

### F1. Plan Compliance Audit - `oracle`
Verify all deliverables from plan exist and work correctly.

### F2. Code Quality Review - `unspecified-high`
Run clippy, fmt, verify no `unwrap()` in production code.

### F3. Terminal Compatibility QA - `unspecified-high`
Test with vim, tmux, htop, complex curses apps.

### F4. Performance Benchmark - `deep`
Verify 60fps with all effects enabled.

---

## Commit Strategy

- **Wave commits**: One commit per wave start
- **Task commits**: Individual commits for significant changes
- **Messages**: `type(scope): description` format
- **Pre-commit**: `cargo check && cargo clippy`

---

## Success Criteria

### Verification Commands
```bash
cargo test --all                    # All tests pass
cargo clippy --all -- -D warnings  # No warnings
./scripts/test-terminal-compat.sh   # Terminal compatibility
./scripts/benchmark-fps.sh          # 60fps verification
```

### Final Checklist
- [ ] All "Must Have" features implemented
- [ ] All "Must NOT Have" guardrails respected
- [ ] 60fps with all shader effects
- [ ] Homebrew install works
- [ ] Accessibility verified with VoiceOver
- [ ] No critical bugs in v1.0

---

## Appendix: Crate Inventory

### Core Crates
```toml
[dependencies]
wgpu = "0.26"
glyphon = "0.6"
cosmic-text = "0.12"
vte = "0.15"
portable-pty = "0.9"
uniffi = "0.28"
```

### Special Crates
```toml
auto-palette = "0.5"
palette = "0.7"
nucleo-matcher = "0.3"
syntect = "5.2"
arboard = "3.4"
accesskit = "0.17"
eazy-tweener = "0.4"
slotmap = "1.0"
```

### Dev Crates
```toml
[dev-dependencies]
criterion = "0.5"  # Benchmarking
insta = "1.40"     # Snapshot testing
```
