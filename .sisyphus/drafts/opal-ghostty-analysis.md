# Opal Terminal Emulator - Competitive Analysis & Improvement Plan

**Date:** 2026-02-22  
**Current Version:** v0.1.2  
**Competitor Benchmark:** Ghostty 1.0+

---

## Executive Summary

Opal is at an early stage (v0.1.2) with basic terminal functionality working but lacking the feature depth and polish of modern terminals like Ghostty. The current implementation has:

- ✅ Working PTY + terminal emulation
- ✅ SwiftUI frontend with basic glass effect
- ✅ FFI bridge between Rust and Swift
- ⚠️ Minimal sidebar (just git status + 2 buttons)
- ❌ No tabs, splits, or multi-window support
- ❌ No GPU-accelerated rendering (using NSTextView)
- ❌ No modern terminal protocols (Kitty graphics, etc.)
- ❌ No configuration system
- ❌ No shell integration

**Strategic Goal:** Reach feature parity with Ghostty within 6 months, then differentiate through unique Liquid Glass implementation and macOS-native features.

---

## 1. Current State Analysis

### 1.1 Architecture Overview

**Opal's Stack:**
- **Core:** Rust (opal-core) - PTY, VTE parser, terminal grid
- **Renderer:** Rust (opal-renderer) - wgpu-based GPU rendering (partially implemented)
- **FFI:** UniFFI (opal-ffi) - Rust ↔ Swift bindings
- **UI:** SwiftUI (Opal/) - Native macOS interface

**Ghostty's Stack (for comparison):**
- **Core:** Zig (performance-critical terminal logic)
- **UI:** Native Swift/AppKit (macOS), GTK (Linux)
- **Renderer:** Metal (macOS), OpenGL (Linux)
- **Philosophy:** Platform-native UI components, not custom-drawn

### 1.2 Feature Gap Analysis

| Feature Category | Opal Status | Ghostty Status | Gap Level |
|-----------------|-------------|----------------|-----------|
| **Core Terminal** | Basic VTE | Full xterm compatibility | 🔴 High |
| **Rendering** | NSTextView | GPU-accelerated Metal | 🔴 High |
| **Tabs/Splits** | ❌ None | ✅ Native implementation | 🔴 High |
| **Sidebar** | Minimal placeholder | Quick Terminal, file navigator | 🔴 High |
| **Themes** | Hardcoded | 200+ themes, auto dark/light | 🟡 Medium |
| **Configuration** | None | Simple text config | 🟡 Medium |
| **Shell Integration** | None | Full integration | 🟡 Medium |
| **Graphics Protocol** | None | Kitty Graphics Protocol | 🟡 Medium |
| **Ligatures** | Basic | Full support | 🟢 Low |
| **Accessibility** | None | Full NSAccessibility | 🔴 High |

### 1.3 Sidebar Deep Dive (Current Implementation)

**Current Sidebar (ContentView.swift:78-103):**
```swift
struct SidebarView: View {
    // Shows:
    // - Git branch name
    // - Git ahead/behind arrows
    // - Git modified/staged counts
    // - "New Terminal" button (restarts session)
    // - "Clear" button (not implemented)
}
```

**Problems:**
1. **Limited functionality** - Only shows git info, no actual file navigation
2. **No session management** - Can't see multiple tabs/sessions
3. **Static display** - Doesn't update dynamically
4. **Poor UX** - Buttons don't do anything useful
5. **No Quick Terminal** - Missing Ghostty's killer feature

---

## 2. Ghostty Competitive Analysis

### 2.1 Ghostty's Core Strengths

1. **Platform-Native UI**
   - Uses real macOS tabs (NSTabViewController), not custom-drawn
   - Native splits using NSSplitView
   - Proxy icon support in title bar
   - Quick Terminal (dropdown from menu bar)

2. **Performance**
   - GPU-accelerated rendering (Metal on macOS)
   - Sub-10ms input-to-photon latency
   - Handles massive output without freezing

3. **Modern Protocols**
   - Kitty Graphics Protocol (images in terminal)
   - Kitty Keyboard Protocol (enhanced key reporting)
   - OSC 8 hyperlinks (clickable URLs)
   - Synchronized rendering (reduces flicker)

4. **Shell Integration**
   - Detects command start/end
   - Shows command duration
   - "Scroll to last command" functionality
   - Copy output of last command

5. **Configuration**
   - Simple text-based config
   - 200+ built-in themes
   - Auto-switching between dark/light themes

### 2.2 Ghostty's Sidebar-Related Features

**Quick Terminal (macOS only):**
- Dropdown terminal from menu bar
- Global hotkey activation
- Perfect for quick commands without leaving current app

**Window Management:**
- Multiple windows
- Tabs per window
- Splits per tab
- All using native macOS components

**Secure Keyboard Entry:**
- Auto-detects password prompts
- Manual toggle with lock icon animation
- Prevents keyloggers from capturing passwords

---

## 3. Improvement Roadmap

### Phase 1: Foundation (Months 1-2)
**Goal:** Fix critical gaps, establish architecture

1. **GPU Rendering Implementation**
   - Complete wgpu/Metal integration
   - Replace NSTextView with GPU-rendered grid
   - Target: <10ms latency

2. **Configuration System**
   - TOML/YAML config file support
   - Theme system (start with 10 themes)
   - Keybinding configuration

3. **Shell Integration**
   - OSC 133 integration (command start/end)
   - Working directory tracking
   - Command duration display

### Phase 2: Sidebar Revolution (Months 2-3)
**Goal:** Transform sidebar from placeholder to killer feature

1. **Session Management Sidebar**
   - Tree view: Windows → Tabs → Panes
   - Drag-and-drop reordering
   - Quick preview of each session
   - Session persistence (restore on launch)

2. **Quick Terminal Feature**
   - Global hotkey (e.g., Cmd+Option+T)
   - Slide-down animation from menu bar
   - Auto-hide when losing focus
   - Independent from main window sessions

3. **File Navigator Sidebar**
   - Tree view of current directory
   - Click to open in editor
   - Git status indicators on files
   - Fuzzy search within directory

4. **Command Palette Sidebar**
   - Search command history
   - Fuzzy match commands
   - Recent directories
   - Bookmarked commands

### Phase 3: Modern Terminal Features (Months 3-4)
**Goal:** Reach feature parity with Ghostty

1. **Tabs & Splits**
   - Native macOS tabs
   - Horizontal/vertical splits
   - Drag-to-rearrange
   - Sync input to multiple panes

2. **Graphics Protocols**
   - Kitty Graphics Protocol
   - Image display in terminal
   - Sixel support (legacy)

3. **Advanced Rendering**
   - Ligatures support
   - Variable font weights
   - Smooth scrolling
   - Animated cursor options

4. **Accessibility**
   - NSAccessibility implementation
   - Screen reader support
   - Reduced motion option
   - High contrast theme

### Phase 4: Differentiation (Months 5-6)
**Goal:** Surpass Ghostty with unique features

1. **Liquid Glass Mastery**
   - Full macOS 15+ Liquid Glass compliance
   - Dynamic blur based on background
   - Refraction effects on text
   - Theme-aware transparency

2. **AI Integration (Optional)**
   - Inline command suggestions
   - Error explanation
   - Natural language to command

3. **Advanced Workflows**
   - Workspace templates
   - Session recording/playback
   - Collaborative sessions

---

## 4. Key Questions for Stakeholders

### 4.1 Product Strategy Questions

**Scope & Positioning:**
1. Is Opal targeting "power users who want a Ghostty alternative" or "general macOS users who want a better Terminal.app"?
2. Should we prioritize feature parity with Ghostty or focus on unique differentiators (Liquid Glass) early?
3. What's the timeline for v1.0? Is 6 months realistic?
4. Do we want to support Linux eventually, or stay macOS-only like current implementation?

**Monetization & Distribution:**
5. Is Opal intended to be open-source forever, or is there a commercial path?
6. Should we target Mac App Store distribution, or direct download?
7. What's the update strategy? Auto-updater like Sparkle?

### 4.2 Sidebar-Specific Questions

**Functionality:**
8. Should the sidebar be collapsible or always-visible?
9. What's the PRIMARY purpose of the sidebar? (Session management? File navigation? Command history?)
10. Should we implement Ghostty's "Quick Terminal" feature as a priority?
11. Do we want a file tree in the sidebar, or integrate with Finder?
12. Should the sidebar show remote server connections (SSH)?

**Design:**
13. Should the sidebar use the same Liquid Glass effect as the terminal, or be more opaque?
14. Do we want multiple sidebar modes (Session view, File view, Command view) with a toggle?
15. Should the sidebar support drag-and-drop of files into the terminal?

### 4.3 Technical Architecture Questions

**Rendering:**
16. Should we complete the wgpu/Metal GPU renderer, or is NSTextView "good enough" for v1.0?
17. What's the target latency? (Ghostty achieves <10ms)
18. Do we want smooth scrolling or instant scrolling?

**Configuration:**
19. TOML (like Ghostty) or YAML for config files?
20. Do we need a GUI preferences panel, or is text config sufficient?
21. Should themes be hot-reloadable without restart?

**Compatibility:**
22. What's the minimum macOS version we want to support? (Ghostty supports 12.0+)
23. Do we need Rosetta support for Intel Macs?
24. Should we support non-ASCII input methods (CJK, Arabic, Hebrew)?

### 4.4 Feature Prioritization Questions

**Must-Have for v1.0:**
25. Rank these in order of importance: Tabs, Splits, GPU rendering, Configuration file, Shell integration, Kitty Graphics
26. Is accessibility (screen reader support) a v1.0 requirement or can it come later?
27. How important is i18n (internationalization) for v1.0?

**Nice-to-Have:**
28. Should we implement a plugin system (like WezTerm's Lua)?
29. Do we want built-in SSH client integration?
30. Should we support terminal multiplexers (tmux integration)?

### 4.5 User Experience Questions

**Onboarding:**
31. Should Opal auto-import settings from Terminal.app or iTerm2?
32. Do we need a "first launch" wizard for configuration?
33. Should we ship with sensible defaults or require initial setup?

**Workflow:**
34. Should Ctrl+T open a new tab or be passed to the terminal application?
35. Do we want a "command palette" (Cmd+Shift+P) like VS Code?
36. Should there be a status bar showing current directory, git branch, etc.?

### 4.6 Development Questions

**Testing:**
37. What's our testing strategy? Unit tests, integration tests, UI tests?
38. Do we need automated performance benchmarks?

**Documentation:**
39. Do we need comprehensive user documentation before v1.0?
40. Should we have a website with feature showcases?

**Community:**
41. Do we want to build a community (Discord, forum) before or after v1.0?
42. What's the contribution model? Open to PRs or core team only?

---

## 5. Technical Recommendations

### 5.1 Immediate Actions (This Week)

1. **Fix Sidebar Transparency**
   - The sidebar currently doesn't match the Liquid Glass aesthetic
   - Make it translucent like the main terminal area
   - Consider using `.ultraThinMaterial` consistently

2. **Implement Basic Tabs**
   - Start with native NSTabViewController
   - Each tab = one PTY session
   - This alone would make Opal dramatically more useful

3. **Add Configuration File**
   - Start simple: `~/.config/opal/config.toml`
   - Support: font, font size, theme, transparency level
   - Hot-reload on file change

### 5.2 Architecture Decisions

**Rendering Pipeline:**
- **Short-term:** Keep NSTextView for v0.2, but wrap it properly
- **Medium-term:** Implement Metal renderer for true GPU acceleration
- **Reference:** Look at Alacritty's alacritty_terminal crate architecture

**Sidebar Architecture:**
```rust
// Suggested FFI additions
enum SidebarMode {
    Sessions,  // Tree of windows/tabs/panes
    Files,     // File navigator
    Commands,  // Command history
    Bookmarks, // Bookmarked dirs/commands
}

interface SidebarState {
    void set_mode(SidebarMode mode);
    void refresh();
    void on_select(callback);
};
```

### 5.3 File Structure Recommendations

Create dedicated sidebar module:
```
Opal/Sources/Opal/Sidebar/
├── SidebarView.swift           // Main container
├── SessionTreeView.swift       // Window/tab/pane tree
├── FileNavigatorView.swift     // File tree
├── CommandHistoryView.swift    // Command search
├── BookmarkView.swift          // Bookmarked items
└── SidebarViewModel.swift      // Shared state
```

---

## 6. Competitive Differentiation Opportunities

While catching up to Ghostty, we can differentiate in these areas:

### 6.1 Liquid Glass Design Leadership

Ghostty uses native UI but doesn't fully embrace Liquid Glass. Opal can:
- Be the first terminal to fully implement Liquid Glass design language
- Dynamic transparency based on wallpaper
- Refraction effects on text
- Smooth, physics-based animations

### 6.2 Developer Experience

- **Zero-config startup** - Works great out of the box
- **Intelligent defaults** - Detects common setups (Node, Python, Rust)
- **Context-aware suggestions** - Sidebar shows relevant tools based on project type

### 6.3 Integration

- **Xcode integration** - Show build logs, device status
- **Docker integration** - Manage containers in sidebar
- **GitHub integration** - PRs, issues in sidebar

---

## 7. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| GPU rendering complexity | High | High | Start with NSTextView, migrate gradually |
| FFI performance bottlenecks | Medium | High | Profile early, batch updates |
| Sidebar scope creep | High | Medium | Define MVP clearly, iterate |
| SwiftUI limitations | Medium | Medium | Fall back to AppKit where needed |
| macOS version fragmentation | Low | Medium | Target macOS 14+ only |

---

## 8. Next Steps

### Immediate (This Session)
1. Review this analysis with stakeholders
2. Answer the 42 questions above
3. Prioritize Phase 1 features

### This Week
1. Implement basic tab support
2. Fix sidebar transparency
3. Add configuration file skeleton

### This Month
1. Complete GPU renderer integration
2. Implement session management sidebar
3. Add shell integration

---

## Appendix A: Ghostty Feature Checklist

**Core Terminal:**
- [x] VT100/xterm compatibility
- [x] 256 colors
- [x] True color (24-bit)
- [x] Mouse support
- [x] Bracketed paste
- [x] Focus events

**Rendering:**
- [x] GPU acceleration
- [x] Ligatures
- [x] Variable fonts
- [x] Custom font features
- [x] Minimum contrast enforcement

**Window Management:**
- [x] Multiple windows
- [x] Native tabs
- [x] Splits (horizontal/vertical)
- [x] Drag-to-rearrange
- [x] Sync input to multiple panes

**Graphics:**
- [x] Kitty Graphics Protocol
- [x] Sixel
- [x] iTerm2 inline images

**Protocols:**
- [x] Kitty Keyboard Protocol
- [x] OSC 8 hyperlinks
- [x] Synchronized rendering
- [x] Colored underlines (curly, dashed)

**Integration:**
- [x] Shell integration (OSC 133)
- [x] Secure keyboard entry
- [x] Proxy icon (macOS)
- [x] Quick Terminal (macOS)

**Configuration:**
- [x] Text config file
- [x] 200+ themes
- [x] Auto dark/light mode
- [x] Keybinding customization

---

## Appendix B: Opal Current Implementation Details

**Working:**
- Basic PTY session
- Terminal grid with VTE parsing
- SwiftUI frontend
- FFI bridge
- Basic transparency
- Cursor blinking
- True color support

**Partial/Stub:**
- GPU renderer (shader files exist, not integrated)
- Sidebar (git info only, not functional)
- Command palette (UI only)

**Not Implemented:**
- Tabs/splits
- Configuration system
- Themes
- Shell integration
- Graphics protocols
- Accessibility
- Multi-window support

---

*This analysis prepared for stakeholder review. Questions should be answered to prioritize development roadmap.*
