---
type: tech_stack
project: Mitro
status: canonical
authority_level: sovereign
last_updated: 2026-05-02
---

# Mitro Tech Stack — Agent-Readable Specification

<context>
This document defines the **immutable technical foundation** of the Mitro engine. All autonomous agents and human developers must validate their work against these constraints before committing code. Deviations require explicit human approval and a `docs(spec):` commit.
</context>

---

## Core Stack Definition

<mandatory_patterns>

### Application Framework
- **Technology:** Tauri 2.0 with Rust backend
- **Constraint:** All filesystem operations MUST flow through Tauri IPC commands
- **Performance Contract:** Cold start <200ms, idle memory <80MB, binary size <10MB
- **Rationale:** Native WebView eliminates Electron bloat while maintaining security boundaries

### Backend Language
- **Technology:** Rust (stable channel, edition 2024)
- **Constraint:** Zero unsafe blocks without explicit justification in code comments
- **Constraint:** All panics must be converted to `Result<T, E>` at public API boundaries
- **Tooling:** `rustfmt` (enforced), `clippy` (zero warnings policy)
- **Rationale:** Memory safety guarantees, zero-cost abstractions, native threading performance

### Data Model
- **Technology:** Local-first pure Markdown (`.md` files)
- **Constraint:** NEVER inject invisible UUID tags or metadata into Markdown files
- **Constraint:** All block references use fuzzy anchoring (Tree-sitter AST + content hash)
- **Constraint:** Files must remain syntactically valid and human-readable at all times
- **Rationale:** Data sovereignty, interoperability, longevity (survives vendor extinction)

### Database Layer
- **Technology:** SQLite with Write-Ahead Logging (WAL)
- **Constraint:** SQLite is ephemeral cache only — NEVER the source of truth
- **Constraint:** MUST open with `PRAGMA journal_mode=WAL` and `PRAGMA synchronous=NORMAL`
- **Constraint:** Database stored in OS cache directory (excluded from cloud sync)
- **Constraint:** Must support full index rebuild from Markdown in <10s for 10,000 files
- **Rationale:** Fast queryable mirror without vendor lock-in risk

### Synchronization Engine
- **Technology:** Loro CRDT v1.0+ (Fugue algorithm)
- **Constraint:** All document state changes MUST flow through Loro — no raw string replacement
- **Constraint:** CRDT metadata never persisted inside `.md` files (in-memory only)
- **Constraint:** Concurrent edits must converge mathematically without conflict markers
- **Rationale:** Prevents `(Sync Conflict)` files, enables human + AI agent collaboration

### File System Monitoring
- **Technology:** `notify` crate (Rust)
- **Constraint:** MUST use native OS primitives (inotify/FSEvents) — polling is banned
- **Constraint:** Self-write exclusion flag mandatory to prevent infinite loops
- **Constraint:** Content-hash every file before triggering parse (xxHash, non-cryptographic)
- **Rationale:** Low CPU overhead, instant external edit detection

### AST Parsing
- **Technology:** Tree-sitter with Markdown grammar
- **Constraint:** Incremental parsing only — full re-parse banned for files >10KB
- **Constraint:** Parse latency <5ms for files up to 50KB
- **Constraint:** AST used for fuzzy anchoring, not for rendering (no UUID pollution)
- **Rationale:** Industry-standard, battle-tested, <5ms incremental updates

### Frontend Framework
- **Technology:** React + TypeScript (strict mode)
- **Constraint:** `tsconfig.json` MUST set `"strict": true` — no escape hatches
- **Constraint:** All Tauri API calls typed with `@tauri-apps/api`
- **Styling:** Tailwind CSS (utility-first, no runtime overhead)
- **Rationale:** Mature ecosystem, strong typing, component reusability

### Editor Core
- **Technology:** ProseMirror or TipTap (decision deferred to Phase 2)
- **Constraint:** MUST support CRDT-compatible document model
- **Constraint:** Keystroke latency <16ms (60fps) under continuous autosave
- **Rationale:** Extensible, production-proven, CRDT-friendly

### AI Integration
- **Technology:** Zero-Token local inference embedded in Rust backend
- **Constraint:** No cloud API calls without explicit user consent
- **Constraint:** Local models via Ollama/LM Studio for privacy-preserving inference
- **Constraint:** Model Context Protocol (MCP) for standardized agent communication
- **Rationale:** Data sovereignty, no IP leakage, offline-first always

### User Experience
- **Technology:** Block-based outliner (Tana-style) rendered from nested Markdown lists
- **Constraint:** Blocks are virtual — derived from AST, not stored as separate entities
- **Constraint:** Drag-and-drop must preserve Markdown list syntax
- **Constraint:** Zoom into blocks without breaking file structure
- **Rationale:** Outliner precision without UUID pollution

</mandatory_patterns>

---

## Banned Practices

<banned_practices>

### Filesystem Access
- ❌ **BANNED:** Node.js `fs` module in any WebView/frontend code
- ❌ **BANNED:** Direct filesystem access from browser context
- ❌ **BANNED:** Synchronous file I/O on main thread
- **Enforcement:** Tauri security allowlist restricts WebView to IPC only

### Data Corruption Vectors
- ❌ **BANNED:** Invisible UUID injection into Markdown files (e.g., `^block123`)
- ❌ **BANNED:** Sidecar JSON files for critical metadata (breaks on external renames)
- ❌ **BANNED:** Proprietary binary formats for user data
- ❌ **BANNED:** Silent data loss or degradation on merge conflicts
- **Enforcement:** Critic-in-the-Loop hook validates Markdown syntax integrity

### Performance Violations
- ❌ **BANNED:** Polling-based file watchers (CPU waste)
- ❌ **BANNED:** Full file re-parse on every keystroke
- ❌ **BANNED:** Synchronous SQLite queries on UI thread
- ❌ **BANNED:** Animations or transitions that degrade <16ms keystroke latency
- **Enforcement:** Performance profiling harness (`MITRO_PERF_LOG=1`)

### Architectural Shortcuts
- ❌ **BANNED:** Raw string replacement instead of CRDT operations
- ❌ **BANNED:** SQLite as source of truth (must be rebuildable from Markdown)
- ❌ **BANNED:** Hardcoded file paths (except `~/Mitro_Test_Vault` in Milestone 0)
- ❌ **BANNED:** Network calls without offline-first fallback
- **Enforcement:** Code review + Critic-in-the-Loop automated validation

### Agent Behavior
- ❌ **BANNED:** Hallucinating completion status without verification
- ❌ **BANNED:** Committing code that fails `cargo fmt` or `cargo clippy`
- ❌ **BANNED:** Merging without Conventional Commits message format
- ❌ **BANNED:** Deleting or weakening tests without explicit human approval
- **Enforcement:** CI pipeline + pre-commit hooks

</banned_practices>

---

## Performance Targets

<rules type="performance">

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Cold Start Time** | <200ms | Time from app launch to interactive UI |
| **Idle Memory Usage** | <80 MB | Activity Monitor after 5 min idle |
| **Keystroke Latency** | <16ms (60fps) | High-speed camera frame analysis |
| **File Read Latency** | <50ms (median) | 100 runs, logged via `std::time::Instant` |
| **File Write Latency** | <50ms (p95) | 60s typing session, performance harness |
| **External Edit Detection** | <200ms | File watcher to UI update |
| **Full-Vault Search** | <500ms | 10,000 files, keyword query to results |
| **SQLite Rebuild** | <10s | 100,000 files, full index reconstruction |

</rules>

---

## Technology Summary

<context type="quick_reference">

| Layer | Technology | Key Property |
|-------|-----------|-------------|
| **Application Framework** | Tauri 2.0 | <200ms start, <80MB RAM, <10MB binary |
| **Backend Language** | Rust (edition 2024) | Memory safety, zero-cost abstractions |
| **Data Format** | Local-first Markdown (`.md`) | Portable, human-readable, eternal |
| **Database** | SQLite (WAL mode) | Ephemeral cache, rebuildable in <10s |
| **Sync Engine** | Loro CRDT (Fugue) | Conflict-free convergence |
| **File Watcher** | `notify` crate | Native OS primitives, low overhead |
| **AST Parser** | Tree-sitter | Incremental, <5ms updates |
| **Frontend** | React + TypeScript | Strict typing, mature ecosystem |
| **Styling** | Tailwind CSS | Utility-first, minimal runtime |
| **Editor** | ProseMirror/TipTap | CRDT-compatible, extensible |
| **AI Runtime** | Ollama/LM Studio | Local inference, zero cloud leakage |
| **Agent Protocol** | Model Context Protocol (MCP) | Standardized tool communication |

</context>

---

## Agent Instructions

<rules type="agent_behavior">

1. **Before writing code:** Read this file + `specs/core_specification.md` + `ROADMAP.md`
2. **Before committing:** Verify no banned practices, all mandatory patterns followed
3. **Performance validation:** Run `MITRO_PERF_LOG=1` harness if touching IPC/CRDT/watcher
4. **Breaking changes:** Require `feat!:` commit with `BREAKING CHANGE:` footer
5. **Uncertainty:** If a constraint conflicts with a requirement, ask human for clarification
6. **Critic-in-the-Loop:** All code must pass adversarial review before merge

</rules>

---

**Authority:** This document is canonical and supersedes verbal instructions. Conflicts resolve in favor of this specification. Revisions require human approval and a `docs(registry):` commit.
