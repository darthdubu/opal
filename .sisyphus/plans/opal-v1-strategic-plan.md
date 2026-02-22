# Opal Strategic Plan v1.0
## Complete Decision Document - All 64 Questions Answered

**Date:** 2026-02-22  
**Version:** 0.1.2 → 1.0 Roadmap  
**Status:** Strategic decisions finalized, ready for execution

---

## Executive Summary

**Opal is the Intelligent Terminal** - a GPU-accelerated, AI-native terminal emulator built from scratch for the AI era. Unlike Ghostty (fast but dumb) or Opencode (AI but no terminal context), Opal combines:

1. **Custom terminal engine** built for AI integration (<5ms latency)
2. **BYOAI Harness** - bring your own AI (Ollama local OR any API provider)
3. **Liquid Glass design** - the first terminal to fully embrace macOS 15+
4. **Terminal-native AI** - context from shell history, git, project structure

**Target:** AI-native developers who use Cursor, Copilot, or Opencode daily  
**Positioning:** *"Opal is the terminal that thinks with you"*  
**Timeline:** 12 months to v1.0 (Month 3: MVP, Month 6: Beta, Month 9: Feature parity, Month 12: Launch)

---

## Part 1: Custom Terminal Engine Decisions (Q43-51)

### ✅ Q43: Why Replace VTE?
**Decision:** Build custom engine from scratch

**Rationale:**
- AI-native architecture requires deep hooks that VTE doesn't provide
- Custom engine enables semantic parsing for AI context extraction
- Marketing differentiation: "Built from scratch for the AI era"
- Target <5ms latency (beating Ghostty's <10ms)

**Timeline cost:** 4 months (16 weeks)  
**Payoff:** Competitive moat, AI-first design, maximum performance

---

### ✅ Q44: Priorities
**Decision:** All 5 priorities confirmed

1. **AI Context Extraction** - Real-time semantic parsing (errors, files, URLs, git ops)
2. **Latency** - <0.5ms parsing overhead (vs 1.5ms VTE)
3. **Memory Efficiency** - 50% less grid memory
4. **GPU-Native** - Direct Metal integration
5. **AI Hooks** - Prediction streaming (<50ms suggestion latency)

---

### ✅ Q45: xterm Compatibility
**Decision:** Pragmatic 95% (modern apps)

**Supported:** vim, emacs, tmux, htop, fzf, ncdu, lazygit, lazyvim, helix, zellij  
**Not supported:** Legacy terminal apps (rarely used)  
**Approach:** Document edge cases, iterate based on user reports  
**Timeline:** 10-12 weeks for compatibility layer

---

### ✅ Q46: Testing Standard
**Decision:** Strict (all tests pass)

**Test Matrix:**
- VTE test suite: 1000+ escape sequences
- Real apps: Daily CI with vim, emacs, tmux, htop, fzf, lazygit
- AI-generated fuzzing: 10k+ random escape sequences
- Compatibility benchmark: Output matches iTerm2

**Definition of Done:** 100% test pass rate, documented known issues (if any)

---

### ✅ Q47: AI Integration Points
**Decision:** All 4 proposed integration points

1. **Semantic Parsing Layer** - Recognize errors, warnings, file paths, URLs, git operations
2. **Context Window** - Keep last 10k lines in structured format for instant AI queries
3. **Prediction Hooks** - Stream typing to AI for suggestions (<50ms latency)
4. **Command Lifecycle Tracking** - Start → Running → Success/Error → AI analysis

**Architecture:** AI is not bolted-on, it's designed into the engine from day 1

---

### ✅ Q48: Performance Targets
**Decision:** Commit to aggressive targets

**Targets:**
- **Parsing:** 2x faster than VTE (0.5ms overhead)
- **Memory:** 50% less than VTE (custom allocators)
- **Latency:** <5ms total input-to-photon (beat Ghostty's <10ms)
- **Throughput:** Handle 1MB/s output without UI freeze

**Benchmarking:** Public dashboard at opal.sh/benchmarks, fail CI on >10% regression

---

### ✅ Q49: ECMA-48 Scope
**Decision:** CSI + OSC sequences

**Must Implement (CSI):**
- Cursor movement (CUP, CUF, CUB, CUD, CUU)
- Colors (256, truecolor)
- Clearing (ED, EL)
- Scrolling (SU, SD)

**Should Implement (OSC):**
- Window title (OSC 0, 2)
- Hyperlinks (OSC 8)
- Clipboard (OSC 52)
- Color palette (OSC 4, 10-19)

**Defer:** DCS sequences (terminfo), rarely used SCS/ACS

---

### ✅ Q50: Development Approach
**Decision:** Reference VTE/Alacritty

**Strategy:**
- Study VTE and Alacritty implementations extensively
- Learn from their architecture decisions and pitfalls
- Write original code (not a fork)
- Adapt patterns for AI-native design

**Benefits:**
- Avoid known bugs and edge cases
- Faster than from-scratch (12-14 weeks vs 14-16)
- Still original code with full control

---

### ✅ Q51: Timeline
**Decision:** 16 weeks (4 months) is reasonable

**MVP Breakdown:**
- Weeks 1-2: CSI sequences (cursor, colors, clearing)
- Weeks 3-4: Color handling (256, truecolor), scrollback buffer
- Weeks 5-6: Input handling, OSC sequences
- Weeks 7-10: Real app testing, edge cases, bug fixes
- Weeks 11-16: Full compatibility, optimization, benchmarking

**Parallel work:** AI Harness development starts Week 1 (separate team/track)

---

## Part 2: AI Harness Architecture Decisions (Q52-64)

### ✅ Q52: AI Harness Definition
**Decision:** Exactly as proposed

**The AI Harness is an intelligent layer that:**
1. **Understands context** - Knows what you're doing, what errors mean, what files you're editing
2. **Anticipates needs** - Suggests commands before you type them
3. **Explains complexity** - Translates errors into human language
4. **Generates solutions** - Writes commands, scripts, configurations
5. **Remembers patterns** - Learns your workflows, preferences, common mistakes

**Think:** Cursor editor's AI, but purpose-built for the terminal

---

### ✅ Q53: Differentiation from Opencode
**Decision:** Hybrid positioning - Terminal context + Code writing

**Positioning:**
- Opal helps USE the terminal (unique context: shell history, git, project structure)
- Opal ALSO helps WRITE code (expand scope beyond just terminal usage)
- Support for ALL major AI providers (user choice)

**Multi-Provider Support:**
- **Local:** Ollama (any local model)
- **Cloud:** OpenRouter, Kimi Code, Claude, OpenAI, Codex
- **Architecture:** Pluggable provider system, user configures their preferred AI

**Research Task:** Analyze Opencode codebase to understand their architecture, then create superior implementation with unique features

---

### ✅ Q54: Killer Features
**Decision:** All 5 proposed features

**Unique to Opal (Opencode CAN'T do these):**

1. **Error Explanation Inline**
   - You see: `error[E0382]: borrow of moved value`
   - Opal shows: Tooltip explaining the error and fix

2. **Command Generation from Natural Language**
   - Type: "find all python files modified today"
   - Opal suggests: `find . -name "*.py" -mtime -1`

3. **Context-Aware Suggestions**
   - Rust project → suggests `cargo` commands
   - Merge conflict → suggests resolution steps
   - Node project → knows this is JavaScript

4. **Automatic Debugging**
   - Command fails → AI auto-analyzes output
   - "Port 3000 in use. Kill the process? [Y/n]"

5. **Workflow Learning**
   - Notices you always `npm test` after `npm install`
   - Suggests: "Run tests now?"

---

### ✅ Q55: Deployment Model
**Decision:** Hybrid (Local + Cloud)

**Local AI (on-device):**
- Small model (3B parameters) for fast suggestions
- Privacy-sensitive operations (password detection)
- Works offline
- Latency: <100ms
- Provider: Ollama (user's choice of model)

**Cloud AI (user's API keys):**
- Large models (Claude, GPT-4, etc.) for complex reasoning
- Error analysis, complex debugging
- Requires internet
- Latency: 1-3s acceptable

**Smart Routing:**
- Simple completion → local
- Error analysis → cloud (if available)
- User choice: "Always local" mode for privacy

---

### ✅ Q56: AI Model Selection
**Decision:** Support ALL providers (multi-provider architecture)

**Supported Providers:**
1. **Ollama** - Local models (free, private)
2. **OpenRouter** - Route to best model for task
3. **Kimi Code** - Code-specific model
4. **Claude 3.5 Sonnet** - Complex reasoning
5. **OpenAI GPT-4** - General tasks
6. **Codex** - Code generation

**Architecture:**
- Pluggable provider system
- User configures preferred AI(s)
- Default: Ollama local + OpenRouter for complex tasks
- Can mix: Local for speed, cloud for complexity

---

### ✅ Q57: Privacy Architecture
**Decision:** Privacy-first (non-negotiable)

**Privacy Principles:**

1. **Data Minimization**
   - Only send relevant context (last 10 commands, current directory)
   - Never send: passwords, API keys, SSH keys (local regex filtering)

2. **User Control**
   - "Incognito mode": No AI logging
   - Granular permissions: "Allow AI to see git status?"
   - Local-only mode: No cloud, ever

3. **Transparency**
   - Show exactly what context is sent to AI
   - Log all AI interactions locally (user can review)
   - Clear indicators when AI is processing

4. **Enterprise**
   - Self-hosted AI option
   - SOC 2 compliance
   - Data retention policies

**Trust is critical:** One privacy scandal kills the product

---

### ✅ Q58: Latency Targets
**Decision:** Aggressive targets as proposed

**Latency Budget:**

| Feature | Target | Max Acceptable |
|---------|--------|----------------|
| Inline completion | 50ms | 150ms |
| Error explanation | 500ms | 2s |
| Command generation | 1s | 3s |
| Complex debugging | 3s | 10s |

**UX Strategy:**
- Fast features: Inline, immediate feedback
- Slow features: Sidebar, async with progress indicator
- Never block terminal input for AI

---

### ✅ Q59: AI Trigger Methods
**Decision:** All 5 methods

**How users trigger AI:**

1. **Natural** - Start typing, AI suggests completions (like Copilot)
2. **Shortcut** - Cmd+I for "Interpret this" (explain error)
3. **Natural Language** - Type `opal: how do I find large files?`
4. **Context Menu** - Right-click → "Explain this"
5. **Proactive** - AI detects error, offers help automatically

**Gradual Discovery:**
- New users: Explicit triggers (shortcut, menu)
- Power users: Inline, proactive suggestions

---

### ✅ Q60: AI UI Patterns
**Decision:** All 5 patterns

**UI Design:**

1. **Inline Suggestions** - Gray text after cursor (Copilot-style), Tab to accept
2. **Sidebar AI Chat** - Conversation thread with Copy/Run buttons
3. **Inline Explanations** - Hover over error → tooltip, Click → sidebar details
4. **Status Bar Indicator** - "AI analyzing..." spinner, "2 suggestions available"
5. **Command Palette** - Cmd+Shift+P → "Ask AI: [prompt]"

**Design Principle:** AI should feel native, not bolted-on

---

### ✅ Q61: AI Context Sources
**Decision:** All 4 sources

**What AI knows:**

1. **Terminal State**
   - Current command line
   - Last 100 commands (with exit codes)
   - Current working directory
   - Environment variables (sanitized)

2. **Project Context**
   - Git status, recent commits, branch
   - Project structure (language detection)
   - Open files (if editor integration available)
   - Dependencies (package.json, Cargo.toml, etc.)

3. **System Context**
   - OS version
   - Shell type (zsh, bash, fish)
   - Installed tools (detected from PATH)

4. **User Preferences** (learned)
   - Preferred languages
   - Common workflows
   - Previous AI interactions

**Context Window:** ~4K tokens, prioritized by relevance

---

### ✅ Q62: Competitive Strategy vs Opencode
**Decision:** Differentiate on terminal context

**Strategy:**
- **Opencode:** Helps write code (editor context)
- **Opal:** Helps USE terminal (shell context) + helps WRITE code (expanded scope)
- **Differentiation:** Terminal-native advantages - shell history, git state, project structure
- **Approach:** Complement Opencode's editor focus with terminal focus

**Key Message:** "Use Opencode in your editor. Use Opal in your terminal. Together they cover your entire workflow."

---

### ✅ Q63: Monetization Model
**Decision:** BYOAI (Bring Your Own AI) - FREE

**Model:**
- **Terminal:** Always free (MIT open source)
- **AI Features:** FREE - users bring their own AI

**How it works:**
- **Local AI:** Connect to Ollama (free, runs on user's machine)
- **Cloud AI:** User provides their own API keys (OpenAI, Claude, etc.)
- **Opal:** Provides the harness, user provides the intelligence

**Revenue Strategy (Alternative):**
- **Free:** BYOAI as described
- **Pro ($10/mo):** Managed AI (we provide API access, optimized routing)
- **Enterprise:** Self-hosted AI, team features, SSO

**Benefits of BYOAI:**
- No AI API costs for us
- Users control their AI spend
- Privacy-first (user controls their data)
- Democratizes access (free for everyone)

---

### ✅ Q64: Build or Partner
**Decision:** Phase 1: Use APIs, Phase 2: Fine-tune, Phase 3: Evaluate

**Phase 1 (Months 1-6): API Integration**
- Use existing APIs (Claude, GPT-4, OpenRouter)
- Focus on harness architecture, not model training
- Ship fast, learn what users want

**Phase 2 (Months 6-9): Fine-tuning**
- Fine-tune open models (Llama, Mistral) for terminal tasks
- Reduce dependency on API providers
- Lower costs, better latency

**Phase 3 (Months 9-12): Evaluation**
- Evaluate: Build custom small model?
- Partner: Co-marketing with Apple (MLX optimization)
- Acquire: Buy small AI startup for talent/tech?

**Decision Point:** Month 9 review to decide Phase 3 direction

---

## Part 3: Sidebar Revolution (Q8-15 recap)

### ✅ Sidebar Decisions Confirmed

**Q8: Collapsible?** Yes, Cmd+Shift+S toggle. Default: collapsed  
**Q9: Primary purpose?** AI Context Management (conversations, suggestions, tools)  
**Q10: Quick Terminal?** Yes - "Quick AI Terminal" (Cmd+Option+Space)  
**Q11: File tree?** AI-augmented file tree with Finder integration  
**Q12: SSH connections?** Yes, with AI-powered management  
**Q13: Liquid Glass?** Yes, 70% transparency (vs 85% terminal)  
**Q14: Multiple modes?** Yes: AI Mode (Cmd+1), Session (Cmd+2), Navigator (Cmd+3), History (Cmd+4)  
**Q15: Drag-and-drop?** Yes, with AI augmentation

**Sidebar is now the "AI Cockpit" not a file browser.**

---

## Part 4: Revised Timeline

### Month 1-3: Foundation (MVP)
**Weeks 1-8: Custom Engine MVP**
- CSI sequences, colors, scrollback
- Input handling, OSC sequences
- Basic AI integration hooks

**Weeks 9-12: AI Harness MVP**
- Multi-provider architecture
- Inline suggestions
- Error explanation

**Deliverable:** Working terminal with basic AI, ship to private beta (100 users)

---

### Month 4-6: Sidebar Revolution (Beta)
**Engine:**
- Real app compatibility (vim, emacs, tmux)
- Performance optimization
- Benchmarking

**AI:**
- Context-aware suggestions
- Command generation
- Workflow learning

**Sidebar:**
- AI Mode implementation
- Session management
- File navigator

**Deliverable:** Public beta, Discord community, feedback loop

---

### Month 7-9: Feature Parity
**Ghostty parity:**
- Tabs (native NSTabViewController)
- Splits (horizontal/vertical)
- Configuration system (TOML)
- Shell integration (OSC 133)

**AI maturity:**
- All 5 killer features
- Multi-provider stability
- Privacy features

**Deliverable:** Feature-complete beta, performance on par with Ghostty

---

### Month 10-12: Launch Prep
**Polish:**
- Liquid Glass perfection
- Accessibility (screen readers)
- Documentation
- Website (opal.sh)

**Launch:**
- v1.0 release
- Hacker News launch
- Product Hunt
- Blog tour

**Deliverable:** v1.0 launch, first paying customers (if Pro tier)

---

## Part 5: Technical Architecture Summary

### System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Opal Terminal                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   SwiftUI UI    │  │   AI Harness    │  │   Sidebar    │ │
│  │  (Liquid Glass) │  │  (BYOAI Model)  │  │  (AI Cockpit)│ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬───────┘ │
│           │                    │                   │        │
│  ┌────────▼────────────────────▼───────────────────▼───────┐ │
│  │                    UniFFI Bridge                       │ │
│  └────────────────────────┬────────────────────────────────┘ │
│                           │                                  │
│  ┌────────────────────────▼────────────────────────────────┐ │
│  │                   Rust Core                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │ │
│  │  │ Custom VTE   │  │ GPU Renderer │  │ AI Context   │  │ │
│  │  │ Engine       │  │ (Metal)      │  │ Extractor    │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │   AI Providers     │
           ┌────────┴──┬────────┬────────┴──┐
           │  Local    │        │   Cloud   │
           │ (Ollama)  │        │ (Multiple)│
           └───────────┘        └───────────┘
```

---

## Part 6: Success Metrics

### Technical Metrics
- **Latency:** <5ms input-to-photon (measured)
- **Compatibility:** 95% test pass rate
- **Performance:** 2x faster parsing than VTE
- **Memory:** 50% less than VTE

### User Metrics
- **Month 3:** 100 private beta users
- **Month 6:** 1,000 public beta users
- **Month 9:** 10,000 active users
- **Month 12:** 50,000 downloads, 10,000 MAU

### Business Metrics (if Pro tier)
- **Month 12:** $10k MRR
- **Month 18:** $50k MRR
- **Month 24:** $200k MRR

---

## Part 7: Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Custom VTE takes >4 months | Medium | High | Ship with reduced compatibility, iterate |
| AI latency > targets | Medium | High | Fallback to cloud-only, optimize later |
| Multi-provider complexity | Medium | Medium | Start with 2 providers, expand gradually |
| Ghostty releases AI features | Low | High | Differentiate on terminal-native context |
| macOS 15+ adoption slow | Low | Medium | Support macOS 14+ with reduced features |

---

## Next Steps

### This Week
1. ✅ **Strategic decisions finalized** (this document)
2. **Start technical spikes:**
   - Prototype custom VTE engine (2 weeks)
   - Prototype AI provider architecture (2 weeks)
   - Benchmark current vs target performance (1 week)
3. **Update CONTINUITY.md** with decisions
4. **Create GitHub issues** for Month 1 tasks

### Month 1
1. Custom engine: CSI sequences, basic grid
2. AI harness: Provider architecture, Ollama integration
3. UI: Sidebar scaffolding, Liquid Glass refinement
4. CI: Test harness, benchmark infrastructure

---

**Document Status:** COMPLETE  
**All 64 Questions:** ANSWERED  
**Ready for:** Execution

*This document represents the definitive strategic direction for Opal v1.0. All major decisions have been made. The focus now shifts to execution.*
