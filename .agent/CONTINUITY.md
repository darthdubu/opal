# Opal Development Continuity

## Current Status

**Version:** 0.2.0 (Month 1 COMPLETE)  
**Last Updated:** 2026-02-22

**Status:** Month 1 foundation complete. CSI/OSC parser implemented.  
**Strategic Plan:** `.sisyphus/plans/opal-v1-strategic-plan.md`

---

## [DECISIONS] Strategic Decisions (All 64 Questions Answered)

### Custom VTE Engine (Q43-51)
- ✅ **Build from scratch** - 16 weeks, 95% compatibility
- ✅ **Priorities:** AI context, latency, memory, GPU-native, AI hooks
- ✅ **Testing:** Strict standard (100% test pass rate)
- ✅ **Performance targets:** <5ms latency, 2x parsing, 50% less memory
- ✅ **Approach:** Reference VTE/Alacritty, write original code

### AI Harness (Q52-64)
- ✅ **Definition:** Intelligent layer (context, anticipation, explanation, generation, learning)
- ✅ **Differentiation:** Terminal-native context + code writing
- ✅ **Deployment:** Hybrid (local 3B + cloud 70B)
- ✅ **Providers:** ALL supported (Ollama, OpenRouter, Kimi, Claude, OpenAI, Codex)
- ✅ **Monetization:** BYOAI - FREE (terminal always free)
- ✅ **Build strategy:** Phase 1 APIs → Phase 2 Fine-tune → Phase 3 Evaluate

---

## [PROGRESS] Month 1 Foundation (In Progress)

### ✅ Completed (2026-02-22)

**Custom VTE Engine Foundation:**
- [x] Create opal-vte crate structure
- [x] Implement Cell with bitflags (bold, italic, underline, etc.)
- [x] Implement Color system (16 basic + 256 palette + RGB truecolor)
- [x] Implement Cursor with movement and styling
- [x] Implement Grid with scrollback buffer (VecDeque)
- [x] Implement ANSI Handler trait for escape sequences
- [x] Add benchmark infrastructure (criterion)

**Architecture:**
- [x] Workspace updated to include opal-vte
- [x] Version bumped to 0.2.0
- [x] Committed: `47bf564` - Month 1 Foundation

### 🔄 In Progress

**Next Tasks:**
- [ ] Implement CSI parser (Control Sequence Introducer)
- [ ] Implement OSC parser (Operating System Command)
- [ ] Create terminal performer (Handler implementation)
- [ ] Add basic tests for grid operations
- [ ] Benchmark current vs VTE

### ⏳ Pending

**Month 1 Remaining:**
- [ ] AI provider architecture crate
- [ ] Ollama integration
- [ ] Multi-provider abstraction
- [ ] Test harness for escape sequences

---

## [PLANS] 12-Month Roadmap

### Month 1: Foundation (Current)
**Goal:** Custom VTE engine foundation + AI architecture

**Week 1-2:**
- ✅ Cell, Color, Cursor, Grid implementation
- 🔄 CSI parser implementation
- ⏳ OSC parser implementation

**Week 3-4:**
- ⏳ Terminal performer (Handler implementation)
- ⏳ Basic scrollback and scrolling
- ⏳ Grid resize handling

**Week 5-6:**
- ⏳ AI provider crate structure
- ⏳ Ollama local integration
- ⏳ Multi-provider abstraction

**Week 7-8:**
- ⏳ Test harness (VTE test suite)
- ⏳ Benchmarks vs existing VTE
- ⏳ Integration with opal-ffi

**Deliverable:** Working terminal grid with basic escape sequence handling

---

### Month 2: Parser & Integration
**Goal:** Complete CSI/OSC support, integrate with SwiftUI

**Week 9-12:**
- Full CSI sequence support (cursor, colors, clearing)
- OSC sequences (title, hyperlinks)
- Performance optimization
- SwiftUI integration for rendering

---

### Month 3: MVP Release
**Goal:** Working terminal with basic AI

**Week 13-16:**
- AI provider integration
- Inline error explanation
- Command generation
- Private beta (100 users)

---

### Month 4-6: Sidebar Revolution
**Goal:** AI Cockpit, public beta

**Features:**
- Sidebar AI Mode
- Session management
- File navigator
- Quick AI Terminal (global hotkey)
- Public beta (1,000 users)

---

### Month 7-9: Feature Parity
**Goal:** Match Ghostty core features

**Features:**
- Native tabs (NSTabViewController)
- Splits (horizontal/vertical)
- Configuration system (TOML)
- Shell integration (OSC 133)
- All 5 killer AI features

---

### Month 10-12: Launch
**Goal:** v1.0 release

**Milestones:**
- Liquid Glass perfection
- Accessibility (screen readers)
- Documentation
- Website (opal.sh)
- Launch: Hacker News, Product Hunt

---

## [TECHNICAL] Architecture

### Crate Structure

```
opal/
├── opal-core/       # Core terminal logic (PTY, etc.)
├── opal-vte/        # 🆕 Custom VTE engine
├── opal-renderer/   # GPU rendering (wgpu/Metal)
├── opal-ffi/        # UniFFI bindings for Swift
└── Opal/            # SwiftUI frontend
```

### opal-vte Module Structure

```
opal-vte/src/
├── lib.rs           # Public API
├── ansi.rs          # Handler trait, modes
├── cell.rs          # Cell with flags
├── color.rs         # Color (Indexed, RGB)
├── cursor.rs        # Cursor position & style
├── grid.rs          # Terminal grid + scrollback
├── handler.rs       # TerminalHandler implementation
├── parser.rs        # 🔄 Escape sequence parser
└── performer.rs     # 🔄 Action performer
```

---

## [METRICS] Performance Targets

### Current (V0.2.0)
- Grid allocation: O(rows * cols)
- Cell operations: O(1)
- Scrollback: VecDeque (amortized O(1))

### Targets (V1.0)
- **Latency:** <5ms input-to-photon
- **Parsing:** 2x faster than VTE (0.5ms overhead)
- **Memory:** 50% less than VTE
- **Throughput:** Handle 1MB/s output without freeze

---

## [RISKS] Risk Register

| Risk | Status | Mitigation |
|------|--------|------------|
| Custom VTE takes >4 months | 🟡 Monitoring | Ship with reduced compatibility |
| AI latency > targets | 🟡 Unvalidated | Fallback to cloud-only |
| SwiftUI performance issues | 🟡 Unvalidated | Fallback to AppKit |
| macOS 15+ adoption slow | 🟢 Low risk | Support 14+ with reduced features |

---

## [NEXT] Immediate Actions

### This Week
1. 🔄 Implement CSI parser (Control Sequence Introducer)
2. 🔄 Implement OSC parser (Operating System Command)
3. ⏳ Create TerminalHandler (Handler trait implementation)
4. ⏳ Add basic tests for escape sequences

### Next Week
5. ⏳ Create opal-ai crate (AI provider architecture)
6. ⏳ Ollama integration
7. ⏳ Multi-provider abstraction

---

## [RESOURCES]

### Documentation
- Strategic Plan: `.sisyphus/plans/opal-v1-strategic-plan.md`
- Competitive Analysis: `.sisyphus/drafts/opal-ghostty-analysis.md`
- Question Answers: `.sisyphus/drafts/opal-strategic-answers.md`

### References
- VTE: https://gitlab.gnome.org/GNOME/vte
- Alacritty terminal: https://github.com/alacritty/alacritty/tree/master/alacritty_terminal
- ANSI escape codes: https://en.wikipedia.org/wiki/ANSI_escape_code
- ECMA-48: https://www.ecma-international.org/publications-and-standards/standards/ecma-48/

---

## [NOTES]

### 2026-02-22
- All 64 strategic questions answered
- Month 1 foundation committed
- Custom VTE engine architecture established
- Next: CSI/OSC parser implementation

### Research Tasks
- [ ] Analyze Opencode codebase for AI architecture patterns
- [ ] Benchmark VTE vs custom grid performance
- [ ] Study Alacritty's parsing implementation

---

*This document is updated continuously as development progresses.*
