# Opal Agent Guidelines

## Global Response Requirement

- In every response, include one thoughtful and relevant suggestion that helps the current situation or proposes a concrete improvement.

## Development Workflow

### Version Numbering

**IMPORTANT**: With each change (feature, bugfix, refactor, or any code modification), revise the version number in the workspace Cargo.toml.

We've made changes since version 0.1.0. This makes it difficult to:
- Track which version is deployed
- Debug issues (users can't report accurate versions)
- Maintain changelog accuracy

**Rule**: Update the version in ALL of the following locations with EVERY code change, no exceptions:
- `Cargo.toml` - workspace.package.version
- `Opal/Sources/Opal/SettingsView.swift` - About section version text (line ~846)

**Version locations to update:**
1. `Cargo.toml` - Main workspace version
2. `Opal/Sources/Opal/SettingsView.swift` - UI About section (search for `Text("X.Y.Z")` in AdvancedSettingsView)

Version format: `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes, major features
- MINOR: New features, significant improvements  
- PATCH: Bug fixes, small changes, refactors, any code modification

**Example workflow**:
1. Make your code changes
2. Update version in Cargo.toml (even for a one-line bugfix)
3. Commit both changes together
4. Include version in commit message: "Fix render loop issue (v0.1.2)"

**When to update**:
- ✅ Feature additions (always)
- ✅ Bug fixes (always)
- ✅ Refactoring (always)
- ✅ Performance improvements (always)
- ✅ Documentation-only changes (optional)
- ✅ Style/formatting only (optional)

## Current Version Tracking

**Current Version: v1.0.16**

Last version update: v1.0.16 (2026-02-23)
- Settings window converted to floating panel
- Terminal transparency fixes for aurora shader
- Terminal prompt positioning fixed
- Version display updated in About section

Next version: Increment based on changes (see rules above)

## Git Version Control

### Commit Best Practices

**Atomic Commits**: Each commit should represent a single logical change
- One feature per commit
- One bug fix per commit  
- Don't bundle unrelated changes together

**Commit Message Format**:
```
<type>: <subject> (vX.Y.Z)

<body - optional but recommended>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, missing semi colons, etc (no code change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Build process, auxiliary tool changes

**Examples**:
```
feat: Add GPU texture atlas caching (v0.1.1)

- Implement glyph caching using wgpu textures
- Reduce CPU-GPU transfer overhead
- Add atlas eviction for memory management

fix: Resolve PTY output buffering issue (v0.1.2)

Root cause: Read buffer too small causing partial escape sequences
Solution: Increase buffer size and add partial sequence handling
```

**Rules**:
1. **NEVER commit broken code** - Code should at least compile/build
2. **NEVER commit secrets** - No API keys, passwords, or tokens
3. **Commit after each logical unit** - Don't accumulate hours of changes
4. **Write descriptive messages** - "Fix bug" is not enough, explain WHAT and WHY
5. **Include version number** in commit message for every version bump
6. **Test before committing** - Run build at minimum

### Git Workflow

**Before committing**:
1. Review your changes with `git diff`
2. Make sure version is updated in Cargo.toml if needed
3. Run `./build.sh` or `cargo build` to verify compilation
4. Write clear commit message

**Commit process**:
```bash
git add -A
git commit -m "fix: Resolve PTY read deadlock (v0.1.1)"
```

**Avoid**:
- `git commit -m "fix"` (too vague)
- `git commit -m "WIP"` (unfinished work)
- `git add .` without reviewing (might include unwanted files)
- Large commits with 10+ files changed (unless it's a major refactor)

### Pre-commit Checklist

- [ ] Code builds without errors (`cargo build` or `./build.sh`)
- [ ] No `println!` or `dbg!` statements left in production code (use `tracing`)
- [ ] No secrets or API keys committed
- [ ] Version updated in Cargo.toml if needed
- [ ] Commit message includes version and describes the change
- [ ] Only relevant files are staged

## Build System

**CRITICAL**: The project has multiple build targets:

### Rust Workspace
The project uses Cargo workspace with three crates:
- **opal-core**: Core terminal emulation logic, PTY handling, VTE parser
- **opal-renderer**: wgpu-based GPU rendering, text layout, glyph caching
- **opal-ffi**: UniFFI bindings for Swift interop

### Build Commands

```bash
# Build the entire Rust workspace
cargo build

# Build for release (optimized)
cargo build --release

# Build Swift app (runs full pipeline)
./build.sh

# Clean build artifacts
cargo clean
```

### Build Output

- `target/debug/` - Debug build output
- `target/release/` - Release build output
- `Opal/` - Swift/SwiftUI application source
- `Opal.app` - Built macOS application bundle

### Swift/macOS Application

The `Opal/` directory contains the Swift/SwiftUI frontend:
- Integrates with Rust core via FFI
- Handles native macOS windowing and events
- Manages application lifecycle

## Project Structure

```
Opal/
├── Cargo.toml              # Workspace manifest
├── Cargo.lock              # Dependency lockfile
├── build.sh                # Full build script (Rust + Swift)
├── rebuild.sh              # Incremental rebuild script
├── opal-core/              # Core terminal emulation
│   ├── src/
│   └── Cargo.toml
├── opal-renderer/          # GPU rendering (wgpu)
│   ├── src/
│   └── Cargo.toml
├── opal-ffi/               # FFI bindings (UniFFI)
│   ├── src/
│   └── Cargo.toml
└── Opal/                   # Swift/SwiftUI app
    ├── Sources/
    ├── Resources/
    └── Package.swift
```

## Key Dependencies

- **wgpu**: Cross-platform GPU abstraction
- **cosmic-text**: Text layout and shaping
- **vte**: Terminal escape sequence parser
- **portable-pty**: PTY (pseudo-terminal) handling
- **uniffi**: Rust-Swift FFI bindings
- **tokio**: Async runtime
- **tracing**: Structured logging

## Development Guidelines

### Rust Code

- Follow standard Rust conventions (cargo fmt, clippy)
- Use `tracing` for logging, not `println!`
- Prefer `thiserror` for error types
- Use `color-eyre` for application errors
- Keep `unsafe` code minimal and well-documented

### Swift Code

- Follow Swift style guidelines
- Use SwiftUI for UI components
- Bridge to Rust via generated FFI bindings
- Handle optional unwrapping safely

### Testing

- Add unit tests for core logic (`cargo test`)
- Test PTY integration manually (platform-specific)
- Test rendering with different terminal applications

## Sunshine Updates

Use this section when wiring or maintaining Sunshine auto-updates in any app.

### Project mapping (fill this first)

- `APP_NAME`: name of distributable app bundle/zip (example: `MyApp`)
- `OWNER`: GitHub owner/org for releases (example: `my-org`)
- `REPO`: GitHub repository name (example: `my-app`)
- `SUNSHINE_REPO`: GitHub repo that hosts Sunshine package source if CI must check it out separately
- `WORKFLOW_FILE`: `.github/workflows/release.yml`

### GitHub Actions release pipeline requirements

- Trigger on tags matching `v*`.
- Create zipped app artifact: `${APP_NAME}.zip`.
- Create EdDSA signature artifact: `${APP_NAME}.sig`.
- Create Sunshine manifest artifact: `update-manifest.json`.
- Upload all artifacts to the GitHub Release for that tag.
- Required secret: `EDDSA_PRIVATE_KEY_BASE64`.
- If your build uses local path package dependencies (for example `../sunshine`), CI must recreate those paths before building.

### Canonical release checklist (known-good process)

- [ ] Confirm `main` is green (build/tests/lint or equivalent).
- [ ] Bump app version in all required surfaces for the project.
- [ ] Ensure workflow version validation (if present) matches the new tag version.
- [ ] Confirm GitHub secret `EDDSA_PRIVATE_KEY_BASE64` is set in the target repo.
- [ ] Commit and push version + release-related changes to `main`.
- [ ] Create and push release tag: `vX.Y.Z`.
- [ ] Verify GitHub Actions `Release` workflow completes successfully.
- [ ] Verify release assets exist:
  - `${APP_NAME}.zip`
  - `${APP_NAME}.sig`
  - `update-manifest.json`
- [ ] Verify `update-manifest.json` points to the exact release tag URL and correct file size/signature.
- [ ] Perform one manual in-app update check from the Settings updates screen.

### App settings integration pattern (generic)

- Add a dedicated settings page/section for updates (example label: `Updates`).
- Persist these values in app settings storage:
  - `owner`
  - `repository`
  - `publicKey`
  - `launchCheckEnabled`
- Initialize Sunshine manager with:
  - `owner`, `repository`
  - `currentVersion`
  - `appName`
  - `publicKey` (recommended default)
  - `automaticLaunchCheckEnabled`
- Expose manual controls:
  - `Check Now`
  - `Download`
  - `Install`
- Render current updater state and last error in UI.

### Security rules

- Never commit private signing keys.
- Store private signing key only in GitHub Secret `EDDSA_PRIVATE_KEY_BASE64`.
- Keep public key in app config/defaults to enforce signature verification.

### Project-specific overrides

Use this small block to pin only repo-local details:

- `APP_NAME`: `Opal`
- `OWNER`: `darthdubu`
- `REPO`: `opal`
- `SUNSHINE_REPO`: `darthdubu/sunshine`
- `WORKFLOW_FILE`: `.github/workflows/release.yml`
- `SETTINGS_STORE_FILE`: `Sources/OpalNext/SunshineUpdateStore.swift`
- `SETTINGS_UI_FILE`: `Sources/OpalNext/SettingsView.swift`
- `PACKAGE_MANIFEST`: `Package.swift`
- `LAST_VERIFIED_RELEASE_TAG`: `v1.3.5`

## Other Guidelines

- Test changes thoroughly before committing
- Use clear commit messages describing the fix
- When fixing critical bugs, prioritize stability over features
- Update documentation when changing public APIs

## Trash

instead of `rm <file_name>` use `trash <file_name>`

instead of `rm -rf <dir_name>` use `trash <dir_name>`

instead of `rmdir <dir_name>` use `trash <dir_name>`

## Misc

### Web search policy

- Enable and use web search only when it materially improves correctness (e.g., up-to-date APIs, recent advisories, release notes).
- Prefer official docs and primary sources; otherwise use Context7 MCP or reputable, widely-cited references.
- Record source dates (publish/release dates) when relevant.

## Baseline workflow

Before starting a task, develop a plan by working backwards from the goal to the steps and actions required to accomplish it.
- Start every task by determining:
  1. Goal + acceptance criteria.
  2. Constraints (time, safety, scope).
  3. What must be inspected (files, commands, tests, docs).
  4. Whether the request depends on **recency** (if yes, apply the "Accuracy, recency, and sourcing" rules).
  5. If requirements are ambiguous, ask targeted clarifying questions before making irreversible changes.

## CONTINUITY.md (REQUIRED)

Maintain a single continuity file for the current workspace: `.agent/CONTINUITY.md`.

- `.agent/CONTINUITY.md` is a living document and canonical briefing designed to survive compaction; do not rely on earlier chat/tool output unless it's reflected there.

- At the start of each assistant turn: read `.agent/CONTINUITY.md` before acting.

### File Format

Update `.agent/CONTINUITY.md` only when there is a meaningful delta in:

  - `[PLANS]`: "Plans Log" is a guide for the next contributor as much as checklists for you.
  - `[DECISIONS]`: "Decisions Log" is used to record all decisions made.
  - `[PROGRESS]`: "Progress Log" is used to record course changes mid-implementation, documenting why and reflecting upon the implications.
  - `[DISCOVERIES]`: "Discoveries Log" is for when when you discover optimizer behavior, performance tradeoffs, unexpected bugs, or inverse/unapply semantics that shaped your approach, capture those observations with short evidence snippets (test output is ideal.
  - `[OUTCOMES]`: "Outcomes Log" is used at completion of a major task or the full plan, summarizing what was achieved, what remains, and lessons learned.

### Anti-drift / anti-bloat rules

- Facts only, no transcripts, no raw logs.
- Every entry must include:
  - a date in ISO timestamp (e.g., `2026-01-13T09:42Z`)
  - a provenance tag: `[USER]`, `[CODE]`, `[TOOL]`, `[ASSUMPTION]`
  - If unknown, write `UNCONFIRMED` (never guess). If something changes, supersede it explicitly (don't silently rewrite history).
- Keep the file bounded, short and high-signal (anti-bloat). 
- If sections begin to become bloated, compress older items into milestone (`[MILESTONE]`) bullets.

## Definition of done

A task is done when:

- the requested change is implemented or the question is answered,
  - verification is provided:
  - build attempted (when source code changed),
  - linting run (when source code changed),
  - errors/warnings addressed (or explicitly listed and agreed as out-of-scope),
  - plus tests/typecheck as applicable,
- documentation is updated exhaustively for impacted areas,
- impact is explained (what changed, where, why),
- follow-ups are listed if anything was intentionally left out.
- `.agent/CONTINUITY.md` is updated if the change materially affects goal/state/decisions.
