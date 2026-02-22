# Opal Strategic Direction: Answers & New Questions

**Date:** 2026-02-22  
**Version:** v0.1.2 → v1.0 Vision  
**Strategic Pivot:** AI-Forward Terminal with Custom High-Performance Engine

---

## Part 1: Answers to Original 42 Questions

### 4.1 Product Strategy Questions - ANSWERED

**Scope & Positioning:**

**Q1: Is Opal targeting "power users who want a Ghostty alternative" or "general macOS users who want a better Terminal.app"?**

**A:** Neither. We're targeting **"AI-native developers"** - engineers who want their terminal to be an intelligent partner, not just a command executor. This is a new category:
- **Primary:** Developers who use AI coding assistants daily (Cursor, GitHub Copilot, Opencode)
- **Secondary:** Power users who prioritize speed and aesthetics
- **Not targeting:** Casual Terminal.app users or traditionalists

**Positioning Statement:** *"Opal is the terminal that thinks with you"*

---

**Q2: Should we prioritize feature parity with Ghostty or focus on unique differentiators early?**

**A:** **Differentiators first, parity second.** Ghostty already exists for people who want Ghostty. We win by being meaningfully different:

**Priority Order:**
1. AI Harness integration (unique value proposition)
2. Custom high-performance terminal engine (speed differentiation)
3. Liquid Glass design mastery (aesthetic differentiation)
4. Ghostty feature parity (table stakes)

**Rationale:** In a crowded market, being 10% better than Ghostty isn't enough. Being different in ways that matter to AI-native developers is.

---

**Q3: What's the timeline for v1.0? Is 6 months realistic?**

**A:** **9-12 months** is more realistic given the scope expansion. Revised timeline:

- **Month 3:** MVP with custom VTE replacement + basic AI integration
- **Month 6:** Sidebar revolution + AI Harness v1
- **Month 9:** Feature parity with Ghostty core features
- **Month 12:** v1.0 launch with full AI capabilities

**Critical path:** Custom terminal engine development is the long pole. VTE replacement is 3-4 months of work.

---

**Q4: Do we want to support Linux eventually, or stay macOS-only?**

**A:** **macOS-only for v1.0, Linux in v2.0.** Rationale:
- Liquid Glass design is macOS 15+ specific (competitive advantage)
- AI Harness integration is easier with unified platform
- macOS market is high-value (developers with disposable income)
- Linux support would add 4-6 months to timeline

**Linux plan:** Abstract platform layer after v1.0, port in v2.0 (months 12-18).

---

**Monetization & Distribution:**

**Q5: Is Opal intended to be open-source forever, or is there a commercial path?**

**A:** **Open core with commercial AI features.** Model:
- **Core terminal:** Open source (MIT) - always free
- **AI Harness:** Freemium - basic features free, advanced models paid
- **Enterprise:** Self-hosted AI, team collaboration, SSO (SaaS)

**Revenue targets:**
- Month 12: Launch with $10/month Pro tier
- Month 18: $50k MRR
- Month 24: $200k MRR

**Why this works:** Terminal is commodity, AI integration is value-add.

---

**Q6: Should we target Mac App Store distribution, or direct download?**

**A:** **Direct download first, Mac App Store later.** Reasons:
- App Store restrictions on AI features (API limitations)
- Need auto-updater for rapid iteration
- Direct download allows beta channels
- App Store for v1.5+ when stable

**Distribution strategy:**
1. Website download (signed, notarized)
2. Homebrew: `brew install opal`
3. Mac App Store (v1.5+)

---

**Q7: What's the update strategy?**

**A:** **Sparkle auto-updater with 3 channels:**
- **Nightly:** Bleeding edge (AI features first)
- **Beta:** Weekly releases (testers)
- **Stable:** Monthly releases (general users)

**Update philosophy:** Ship fast, iterate with AI features driving updates.

---

### 4.2 Sidebar-Specific Questions - ANSWERED

**Functionality:**

**Q8: Should the sidebar be collapsible or always-visible?**

**A:** **Collapsible with keyboard toggle (Cmd+Shift+S).** Default: collapsed for minimal UI, but:
- **AI Mode:** Sidebar expands to show AI chat/conversations
- **Session Mode:** Shows tab/pane tree
- **File Mode:** Shows project navigator
- **Command Mode:** Shows command history + AI suggestions

**Smart behavior:** Auto-expand when AI is active, collapse when typing commands.

---

**Q9: What's the PRIMARY purpose of the sidebar?**

**A:** **AI Context Management.** The sidebar is where you:
1. **Manage AI conversations** (like ChatGPT threads, but terminal-native)
2. **See AI suggestions** inline with command history
3. **Access AI-powered tools** (explain error, generate command, debug output)
4. **Browse AI-augmented project context** (smart file nav)

**Secondary:** Session management (tabs/splits)

**This redefines the sidebar from "file browser" to "AI cockpit."**

---

**Q10: Should we implement Ghostty's "Quick Terminal" feature as a priority?**

**A:** **Yes, but with AI twist: "Quick AI Terminal."** 

Instead of just a dropdown terminal, it's:
- **Global hotkey** (Cmd+Option+Space)
- **AI-first interface** - starts with AI prompt, not shell
- **Context-aware** - knows what you were working on
- **Transient** - disappears after task complete

**Use case:** "Hey Opal, fix this error" → AI analyzes clipboard/context → gives solution → terminal disappears.

---

**Q11: Do we want a file tree in the sidebar, or integrate with Finder?**

**A:** **AI-augmented file tree with Finder integration.**

**Features:**
- Smart file tree (hides node_modules, .git, etc.)
- **AI annotations** - "This file was recently modified" or "Related to current task"
- Drag-drop from Finder into terminal (create path)
- Drag-drop from sidebar to Finder (reveal in Finder)
- **AI search:** "Find files related to auth" uses embeddings

**Not:** Dumb file tree like VS Code.

---

**Q12: Should the sidebar show remote server connections (SSH)?**

**A:** **Yes, with AI-powered SSH management.**

**Features:**
- Save SSH connections with AI-generated descriptions
- "Connect to staging server" (AI knows which one)
- AI suggests commands based on server type ("You're on Ubuntu, use apt not brew")
- Sync terminal sessions across local + remote
- **AI security:** Warns about dangerous commands on production

---

**Design:**

**Q13: Should the sidebar use the same Liquid Glass effect as the terminal?**

**A:** **Yes, but with subtle differentiation.**
- Terminal: 85% transparency (focus on content)
- Sidebar: 70% transparency (slightly more opaque for readability)
- AI chat bubbles: Frosted glass effect (90% transparency)
- **Adaptive:** Sidebar darkens when AI is typing (visual feedback)

---

**Q14: Do we want multiple sidebar modes?**

**A:** **Yes, 4 modes with AI Mode as default:**

1. **AI Mode** (Cmd+1): Conversations, suggestions, context
2. **Session Mode** (Cmd+2): Tabs, splits, windows
3. **Navigator Mode** (Cmd+3): AI-augmented file tree
4. **History Mode** (Cmd+4): Command history with AI insights

**Smart switching:** Contextual - if you just got an error, auto-switch to AI Mode.

---

**Q15: Should the sidebar support drag-and-drop of files into the terminal?**

**A:** **Yes, with AI augmentation:**
- Drag file → types path (basic)
- Drag file + hold Option → "What is this file?" (AI explains)
- Drag file + hold Cmd → "How do I use this?" (AI suggests commands)
- Drag multiple files → AI asks "What do you want to do with these?"

---

### 4.3 Technical Architecture Questions - ANSWERED

**Rendering:**

**Q16: Should we complete the wgpu/Metal GPU renderer, or is NSTextView "good enough"?**

**A:** **Full Metal renderer is REQUIRED for performance goals.** NSTextView won't achieve:
- Sub-10ms latency
- Smooth 120Hz scrolling
- AI overlay rendering
- Complex animations

**Plan:**
- Month 1-2: Complete Metal renderer (parallel with VTE work)
- Month 3: Benchmark vs Ghostty
- Target: **<5ms latency** (beat Ghostty's <10ms)

---

**Q17: What's the target latency?**

**A:** **<5ms input-to-photon.** Aggressive target:
- Typing: 1-2ms (immediate feedback)
- Scrolling: 5ms (smooth 120Hz)
- AI overlay: 8ms (acceptable for non-interactive)

**Why this matters:** When AI is generating text, latency perception is critical.

---

**Q18: Do we want smooth scrolling or instant scrolling?**

**A:** **Both, user-configurable with physics-based smooth as default.**

**Modes:**
- **Smooth** (default): Physics-based, momentum scrolling like iOS
- **Instant:** For power users who hate animation
- **Smart:** Instant for small scrolls, smooth for large

**AI integration:** AI can suggest "scroll to relevant section" with animated scroll.

---

**Configuration:**

**Q19: TOML or YAML for config files?**

**A:** **TOML, with AI-assisted configuration.**
- `~/.config/opal/config.toml` (standard)
- `~/.config/opal/ai.toml` (AI-specific settings)
- **AI command:** "Make my terminal more transparent" → AI edits config

---

**Q20: Do we need a GUI preferences panel?**

**A:** **Minimal GUI panel, text config preferred.**

**Philosophy:** Power users edit text, casual users use defaults.

**GUI panel shows:**
- Theme picker with preview
- Font selection
- AI enable/disable
- Transparency slider

**Everything else:** Text config with AI help.

---

**Q21: Should themes be hot-reloadable?**

**A:** **Yes, instantly.** Change config → see change in <100ms.

**AI theme generation:** "Make a theme like sunset" → AI generates colors → hot reloads.

---

**Compatibility:**

**Q22: What's the minimum macOS version?**

**A:** **macOS 15.0 (Sequoia) minimum.** Rationale:
- Liquid Glass requires macOS 15+
- AI features need Neural Engine (Apple Silicon)
- 92% of devs on macOS 15+ (aggressive but acceptable)

**Intel Macs:** Not supported (no Neural Engine for AI).

---

**Q23: Do we need Rosetta support?**

**A:** **No.** Apple Silicon only. This simplifies:
- Metal shader compilation
- AI model execution
- Testing matrix

---

**Q24: Should we support non-ASCII input methods?**

**A:** **Yes, Phase 2.** Critical for:
- CJK developers (huge market)
- Emoji input
- International teams

**Timeline:** Basic Unicode in v1.0, advanced IME in v1.5.

---

### 4.4 Feature Prioritization Questions - ANSWERED

**Must-Have for v1.0:**

**Q25: Rank features by importance:**

**A:** Revised ranking for AI-forward terminal:

1. **Custom VTE replacement** (foundation for everything)
2. **AI Harness** (core differentiator)
3. **GPU rendering** (performance requirement)
4. **Configuration system** (AI needs config)
5. **Tabs** (basic UX)
6. **Shell integration** (enables AI context)
7. **Splits** (nice to have)
8. **Kitty Graphics** (v1.5 feature)

**Rationale:** AI without performance is frustrating. Performance without AI is just another terminal.

---

**Q26: Is accessibility a v1.0 requirement?**

**A:** **Yes, non-negotiable.** AI features must be accessible:
- Screen reader support for AI responses
- Voice control integration ("Hey Opal, fix this")
- High contrast themes
- Reduced motion for AI animations

**Ethical AI:** AI that's not accessible amplifies inequality.

---

**Q27: How important is i18n for v1.0?**

**A:** **English only for v1.0, i18n in v1.5.** But:
- AI can respond in any language (LLM capability)
- UI remains English initially
- Add i18n when expanding to international markets

---

**Nice-to-Have:**

**Q28: Should we implement a plugin system?**

**A:** **Yes, but AI-first:** Plugins are AI prompts, not code.

**Example:**
- Traditional: Python plugin for Docker integration
- Opal: AI prompt "When I type 'docker', suggest useful commands"

**Plugin marketplace:** Curated AI prompt templates.

---

**Q29: Built-in SSH client?**

**A:** **No, use native SSH with AI wrapper.**
- Don't reinvent SSH
- AI layer on top: "ssh to staging" (AI knows which server)
- AI suggests SSH configs, warns about security

---

**Q30: tmux integration?**

**A:** **Not needed - we have native splits.** tmux is a workaround for bad terminals. Opal makes tmux unnecessary.

**Migration path:** Import tmux sessions during onboarding.

---

### 4.5 User Experience Questions - ANSWERED

**Onboarding:**

**Q31: Should Opal auto-import settings from Terminal.app/iTerm2?**

**A:** **Yes, with AI-powered migration:**
- Import: Font, colors, keybindings, shell
- **AI analysis:** "You use these iTerm2 features, here's how Opal does it better"
- Migrate shell history (optional)
- Convert iTerm2 themes to Opal format

---

**Q32: Do we need a "first launch" wizard?**

**A:** **Yes, AI-guided onboarding:**
1. "What's your primary language/stack?" (AI customizes suggestions)
2. "Do you use AI coding assistants?" (explains Opal AI integration)
3. "Import from another terminal?" (migration)
4. "Pick a theme" (Liquid Glass preview)

**Time to first command:** <30 seconds.

---

**Q33: Sensible defaults or require initial setup?**

**A:** **Sensible defaults, AI-enhanced:**
- Font: SF Mono (native, beautiful)
- Theme: Adaptive Liquid Glass
- AI: Enabled with privacy-first local models
- Transparency: 85% (looks great out of box)

**Zero config to start, AI helps customize over time.**

---

**Workflow:**

**Q34: Should Ctrl+T open a new tab or be passed to terminal?**

**A:** **New tab by default, configurable.** Most users expect Ctrl+T for tabs.

**AI suggests:** "You use vim - want to remap Ctrl+T to pass through?"

---

**Q35: Do we want a command palette?**

**A:** **Yes, Cmd+Shift+P for "AI Command Palette":**
- Traditional: "Open settings"
- Opal: "Explain this error", "Generate git commit", "Optimize this command"

**Fuzzy search + AI suggestions combined.**

---

**Q36: Status bar?**

**A:** **Yes, minimal with AI context:**
- Left: Current directory, git branch
- Center: AI status ("AI ready", "Analyzing...", "2 suggestions")
- Right: Command duration, exit status

**Click AI status:** Opens sidebar AI Mode.

---

### 4.6 Development Questions - ANSWERED

**Testing:**

**Q37: What's our testing strategy?**

**A:** **Multi-layer with AI-assisted testing:**

1. **Unit tests:** Rust core (target: 80% coverage)
2. **Integration tests:** FFI layer, PTY communication
3. **UI tests:** SwiftUI interactions (XCUITest)
4. **AI tests:** Prompt quality, response accuracy
5. **Performance tests:** Latency benchmarks, memory usage
6. **Compatibility tests:** VTE compliance suite

**AI-generated tests:** AI writes test cases based on code changes.

---

**Q38: Automated performance benchmarks?**

**A:** **Yes, CI benchmarks on every PR:**
- Latency: typing, scrolling, AI response
- Memory: baseline, stress test, AI active
- Comparison: vs Ghostty, vs iTerm2
- **Fail CI if:** >10% regression

**Public dashboard:** opal.sh/benchmarks

---

**Documentation:**

**Q39: Comprehensive user documentation before v1.0?**

**A:** **Yes, AI-generated + human-curated:**
- AI writes initial docs from code
- Humans edit for clarity
- Interactive tutorials in terminal ("Try this!")
- Video walkthroughs for AI features

---

**Q40: Website with feature showcases?**

**A:** **Yes, opal.sh with interactive demos:**
- Live terminal in browser (WebAssembly)
- AI feature demos
- Performance comparison charts
- Theme gallery with "Try it" button

**Marketing site:** Ship 2 months before v1.0 (Month 10).

---

**Community:**

**Q41: Community before or after v1.0?**

**A:** **After Month 6 (beta launch).** Timeline:
- Month 1-3: Stealth development
- Month 4-6: Private beta (100 users)
- Month 7-9: Public beta + Discord
- Month 10-12: Community building

**Premature community distracts from building.**

---

**Q42: Contribution model?**

**A:** **Open to PRs with AI-assisted review:**
- Core terminal: Maintainers only (complex, stability-critical)
- AI features: Community contributions welcome
- Themes: Full community (theme marketplace)
- Documentation: Everyone

**AI code review:** AI pre-reviews PRs, flags issues, suggests improvements.

---

## Part 2: NEW Questions - Custom VTE Replacement

### 5.1 Architecture & Scope

**Q43: Why replace VTE instead of using it?**

**A:** [DECISION REQUIRED]

**Arguments for custom:**
- **Performance:** Zero overhead, optimized for our exact use case
- **AI integration:** Deep hooks for AI context extraction
- **Differentiation:** "Built from scratch for the AI era" marketing
- **Control:** No dependency on external project roadmap

**Arguments against:**
- **Time:** 3-4 months additional development
- **Bugs:** VTE is battle-tested, custom code has unknown bugs
- **Compatibility:** Risk of edge cases not handled
- **Maintenance:** Ongoing burden to maintain compatibility

**Hybrid option:** Use VTE for v1.0, build custom in parallel for v2.0?

---

**Q44: What specific VTE limitations are we solving?**

**A:** [TECHNICAL SPECIFICATION REQUIRED]

Current hypotheses:
- **Latency:** VTE parsing overhead adds 1-2ms
- **AI context extraction:** VTE doesn't expose semantic context easily
- **Memory:** Custom grid can be more memory-efficient
- **Rendering coupling:** VTE assumes CPU rendering, we want GPU

**Need benchmarks:** Profile VTE vs custom to validate assumptions.

---

**Q45: What level of xterm compatibility do we need?**

**A:** [SCOPE DEFINITION REQUIRED]

**Options:**
1. **Full xterm:** 100% compatibility (massive effort)
2. **Pragmatic:** 95% compatibility (most apps work, edge cases documented)
3. **Modern only:** Support modern apps, legacy apps use fallback

**Recommendation:** Start with #2 (pragmatic), measure what breaks.

---

**Q46: How do we test custom terminal engine compatibility?**

**A:** [TESTING STRATEGY REQUIRED]

**Test matrix:**
- **VTE test suite:** 1000+ sequences
- **Real apps:** vim, emacs, tmux, htop, ncdu, fzf
- **AI-generated tests:** "Generate escape sequences that might break"
- **Fuzzing:** Random escape sequence injection

**CI requirement:** All tests pass before merge.

---

### 5.2 AI Integration in Terminal Engine

**Q47: How does custom engine enable AI features?**

**A:** [ARCHITECTURE DESIGN REQUIRED]

**Proposed integration points:**

1. **Semantic parsing layer:**
   - Recognize: errors, warnings, file paths, URLs, git operations
   - Expose to AI: "Current command is `cargo build`, got error E0382"

2. **Context window:**
   - Keep last 10k lines in structured format
   - AI queries: "What was the last error?" → instant response

3. **Prediction hooks:**
   - As user types, stream to AI for suggestions
   - Latency: <50ms for suggestion appearance

4. **Command lifecycle tracking:**
   - Start → Running → Success/Error → AI analysis
   - Automatic "What went wrong?" on error

**This is the core value of custom engine: AI-native architecture.**

---

**Q48: What's the performance target for custom engine?**

**A:** [METRICS DEFINITION REQUIRED]

**Targets vs VTE:**
- **Parsing:** 2x faster escape sequence handling
- **Memory:** 50% less grid memory
- **Latency:** 0.5ms parsing overhead (vs 1.5ms VTE)
- **Throughput:** Handle 1MB/s output without freezing UI

**Benchmark:** Create test harness with common workloads.

---

**Q49: Do we implement full ECMA-48 or subset?**

**A:** [TECHNICAL SCOPE REQUIRED]

**ECMA-48 scope:**
- **Must implement:** CSI sequences (cursor, colors, clearing)
- **Should implement:** OSC sequences (title, hyperlinks, clipboard)
- **Nice to have:** DCS sequences (terminfo queries)
- **Defer:** Rarely used sequences (SCS, ACS)

**Iterative approach:** Implement on-demand as apps need them.

---

### 5.3 Development Strategy

**Q50: Build from scratch or fork/reference VTE?**

**A:** [APPROACH DECISION REQUIRED]

**Option A: From scratch**
- Pros: Clean slate, AI-native design
- Cons: 4-5 months, compatibility risk

**Option B: Reference VTE implementation**
- Pros: Learn from tested code, avoid known pitfalls
- Cons: License considerations (LGPL), may copy bad decisions

**Option C: Use Alacritty's alacritty_terminal crate**
- Pros: Rust, MIT licensed, proven
- Cons: Tied to Alacritty architecture, less flexible

**Recommendation:** Start with Option C (Alacritty), customize heavily, replace components over time.

---

**Q51: How long to build minimum viable custom engine?**

**A:** [TIMELINE ESTIMATE REQUIRED]

**MVP scope (80% of daily use):**
- Basic CSI sequences: 2 weeks
- Color handling (256, truecolor): 1 week
- Scrollback buffer: 2 weeks
- Input handling: 1 week
- **Total: 6 weeks for MVP**

**Full compatibility:** Additional 8-10 weeks.

**Risk mitigation:** Ship with VTE, switch to custom once ready.

---

## Part 3: NEW Questions - AI Harness Architecture

### 6.1 Product Definition

**Q52: What exactly is the AI Harness?**

**A:** [PRODUCT DEFINITION REQUIRED]

**Proposed definition:**
An intelligent layer between the user and the terminal that:
1. **Understands context:** Knows what you're doing, what errors mean, what files you're editing
2. **Anticipates needs:** Suggests commands before you type them
3. **Explains complexity:** Translates errors into human language
4. **Generates solutions:** Writes commands, scripts, configurations
5. **Remembers patterns:** Learns your workflows, preferences, common mistakes

**Think:** Cursor editor's AI, but for the terminal.

---

**Q53: How does Opal AI differ from Opencode?**

**A:** [COMPETITIVE POSITIONING REQUIRED]

**Opencode model:**
- Standalone AI coding assistant
- Separate app, separate context
- General-purpose coding help

**Opal AI model:**
- **Context-aware:** Lives in your terminal, knows your shell history, current directory, git state
- **Action-oriented:** Doesn't just suggest, it executes (with permission)
- **Integrated:** Part of the terminal, not a separate tool
- **Proactive:** Watches for errors, offers help before you ask

**Differentiation:** "Opencode helps you write code. Opal helps you use the terminal."

---

**Q54: What are the killer AI features that Opencode can't do?**

**A:** [FEATURE INNOVATION REQUIRED]

**Unique to Opal (terminal context):**

1. **Error explanation inline:**
   - You see: `error[E0382]: borrow of moved value`
   - Opal shows: Tooltip "This means you're trying to use a variable after giving ownership to another function. Here's how to fix it..."

2. **Command generation from natural language:**
   - Type: "find all python files modified today"
   - Opal suggests: `find . -name "*.py" -mtime -1`

3. **Context-aware suggestions:**
   - You're in a Rust project → suggests `cargo` commands
   - You just got a merge conflict → suggests resolution steps
   - You're in `~/projects/myapp` → knows this is a Node project

4. **Automatic debugging:**
   - Command fails → AI automatically analyzes output
   - "It looks like port 3000 is already in use. Kill the process? [Y/n]"

5. **Workflow learning:**
   - Notices you always run `npm test` after `npm install`
   - Suggests: "Run tests now?"

**None of these are possible for Opencode (no terminal context).**

---

### 6.2 Technical Architecture

**Q55: Local AI, cloud AI, or hybrid?**

**A:** [ARCHITECTURE DECISION REQUIRED]

**Hybrid approach (recommended):**

**Local (on-device):**
- Small model (3B parameters) for fast suggestions
- Privacy-sensitive operations (password detection, SSH keys)
- Works offline
- Latency: <100ms

**Cloud:**
- Large model (70B+) for complex reasoning
- Error analysis, complex debugging
- Requires internet
- Latency: 1-3s acceptable

**Smart routing:**
- Simple completion → local
- Error analysis → cloud
- User choice: "Always local" mode for privacy

---

**Q56: What AI model do we use?**

**A:** [TECHNOLOGY SELECTION REQUIRED]

**Local options:**
- **llama.cpp:** Fast, efficient, MIT license
- **MLX (Apple):** Optimized for Apple Silicon, best performance
- **ollama:** Easy deployment, model management

**Cloud options:**
- **OpenAI GPT-4:** Best quality, expensive
- **Anthropic Claude:** Excellent for technical tasks
- **Self-hosted:** Cost-effective, more control

**Recommendation:**
- Local: MLX with fine-tuned 3B model
- Cloud: Claude 3.5 Sonnet via API

**Fine-tuning:** Train on terminal-specific tasks.

---

**Q57: How do we handle privacy with AI?**

**A:** [PRIVACY ARCHITECTURE REQUIRED]

**Privacy-first design:**

1. **Data minimization:**
   - Only send relevant context (last 10 commands, current directory)
   - Never send: passwords, API keys, SSH keys (local regex filtering)

2. **User control:**
   - "Incognito mode": No AI logging
   - Granular permissions: "Allow AI to see git status?"
   - Local-only mode: No cloud, ever

3. **Transparency:**
   - Show exactly what context is sent to AI
   - Log all AI interactions locally (user can review)

4. **Enterprise:**
   - Self-hosted AI option
   - SOC 2 compliance
   - Data retention policies

**Trust is critical.** One privacy scandal kills the product.

---

**Q58: What's the latency budget for AI features?**

**A:** [PERFORMANCE REQUIREMENTS REQUIRED]

**Latency targets:**

| Feature | Target | Max Acceptable |
|---------|--------|----------------|
| Inline completion | 50ms | 150ms |
| Error explanation | 500ms | 2s |
| Command generation | 1s | 3s |
| Complex debugging | 3s | 10s |

**UX strategy:**
- Fast features: Inline, immediate
- Slow features: Sidebar, async with progress indicator
- Never block terminal input for AI

---

### 6.3 User Experience

**Q59: How do users trigger AI?**

**A:** [UX DESIGN REQUIRED]

**Trigger methods:**

1. **Natural:** Start typing, AI suggests completions (like Copilot)
2. **Shortcut:** Cmd+I for "Interpret this" (explain error)
3. **Natural language:** Type `opal: how do I find large files?`
4. **Context menu:** Right-click → "Explain this"
5. **Proactive:** AI detects error, offers help automatically

**Gradual discovery:**
- New users: Explicit triggers
- Power users: Inline, proactive

---

**Q60: How does AI UI look in the terminal?**

**A:** [UI/UX DESIGN REQUIRED]

**UI patterns:**

1. **Inline suggestions:**
   - Gray text after cursor (like Copilot)
   - Tab to accept, Esc to dismiss
   - Fade in animation

2. **Sidebar AI chat:**
   - Conversation thread
   - Code blocks with "Copy" / "Run" buttons
   - File references clickable

3. **Inline explanations:**
   - Hover over error → tooltip with explanation
   - Click to expand full details in sidebar

4. **Status bar indicator:**
   - "AI analyzing..." spinner
   - "2 suggestions available"
   - Click to see suggestions

5. **Command palette:**
   - Cmd+Shift+P → "Ask AI: [prompt]"

**Design principle:** AI should feel native, not bolted-on.

---

**Q61: What does AI know about context?**

**A:** [CONTEXT MODEL REQUIRED]

**Context sources:**

1. **Terminal state:**
   - Current command line
   - Last 100 commands (with exit codes)
   - Current working directory
   - Environment variables (sanitized)

2. **Project context:**
   - Git status, recent commits
   - Project structure (language detection)
   - Open files (if editor integration)

3. **System context:**
   - OS version
   - Shell type (zsh, bash, fish)
   - Installed tools (detected from PATH)

4. **User preferences:**
   - Preferred languages
   - Common workflows
   - Previous AI interactions (learned)

**Context window:** ~4K tokens, prioritized by relevance.

---

### 6.4 Competitive Strategy

**Q62: How do we compete with Opencode?**

**A:** [COMPETITIVE STRATEGY REQUIRED]

**Opencode advantages:**
- Established brand
- Multi-platform
- General-purpose (not just terminal)
- Existing user base

**Opal advantages:**
- **Context depth:** Lives in terminal, knows shell history
- **Integration:** Executes commands, not just suggests
- **Proactive:** Detects errors automatically
- **Native:** macOS-native, Liquid Glass design
- **Performance:** Local AI for speed

**Strategy:**
1. **Differentiate on context:** "Opencode helps write code. Opal helps use the terminal."
2. **Complement, don't replace:** Many users will use both
3. **Niche down:** Focus on macOS power users initially
4. **Speed:** Local AI is faster than Opencode's cloud

**Not a zero-sum game:** Terminal AI and editor AI serve different workflows.

---

**Q63: What's the monetization model for AI?**

**A:** [BUSINESS MODEL REQUIRED]

**Freemium tiers:**

**Free:**
- Local AI only (limited capability)
- 50 cloud AI requests/month
- Basic error explanations

**Pro ($15/month):**
- Unlimited local AI
- 1000 cloud AI requests/month
- Advanced debugging
- Custom AI personalities

**Team ($25/user/month):**
- Shared AI context (team learns together)
- Admin controls
- Priority support
- Self-hosted AI option

**Enterprise (custom):**
- Unlimited everything
- Self-hosted
- SSO, audit logs
- Custom model training

**Cost structure:**
- Local AI: Free (runs on user's machine)
- Cloud AI: ~$0.01 per request (API costs)
- Break-even: Pro users at $15/month cover costs

---

**Q64: Do we partner with AI companies or build our own?**

**A:** [PARTNERSHIP STRATEGY REQUIRED]

**Phase 1 (v1.0):**
- Use existing APIs (Claude, GPT-4)
- Focus on integration, not model training
- Ship fast, learn what users want

**Phase 2 (v1.5):**
- Fine-tune open models for terminal tasks
- Reduce dependency on API providers
- Lower costs, better latency

**Phase 3 (v2.0):**
- Evaluate: Build custom small model?
- Partner: Co-marketing with Apple (MLX)?
- Acquire: Buy a small AI startup?

**Recommendation:** Start with APIs, gradually move to self-hosted fine-tuned models.

---

## Summary: 64 Questions Total

### Original Questions (42): ✅ ANSWERED
All questions answered with AI-forward strategic direction.

### New VTE Questions (9): ⚠️ REQUIRE DECISION
- Q43-46: Architecture and scope
- Q47-48: AI integration in engine
- Q49: ECMA-48 scope
- Q50-51: Development strategy

### New AI Harness Questions (13): ⚠️ REQUIRE DECISION
- Q52-54: Product definition
- Q55-58: Technical architecture
- Q59-61: User experience
- Q62-64: Competitive strategy

---

## Immediate Next Steps

**This Week:**
1. **Review all 64 answers** - validate strategic direction
2. **Decide on VTE vs Custom** - critical path decision
3. **Define AI Harness MVP** - what's the minimum viable AI feature set?
4. **Prioritize first 3 months** - what's shipping in Month 1?

**Technical Spikes:**
1. Prototype custom terminal engine (2 weeks)
2. Prototype AI integration with MLX (2 weeks)
3. Benchmark VTE vs custom (1 week)

**Risk Mitigation:**
- If custom VTE is too hard, fall back to Alacritty crate
- If AI is too slow, focus on local-only features
- If timeline slips, cut features not core to AI differentiation

---

*This document represents a bold strategic pivot. The combination of custom high-performance terminal engine + AI Harness positions Opal as a new category: the Intelligent Terminal.*
