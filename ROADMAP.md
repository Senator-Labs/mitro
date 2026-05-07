---
type: roadmap
project: Mada
milestone: 0
status: active
authority_level: execution
last_updated: 2026-05-07
version_baseline: v0.0.0.0.1
version_target: v0.0.0.1.0
versioning_spec: specs/versioning.md
---

# Mada — Milestone 0 Roadmap: Engine Test

**Philosophy:** Risk-First. Prove the three core technical hypotheses before any UI polish, branding, or feature work.

**Exit Criteria for Milestone 0:**
1. Tauri window opens `~/Mada_Test_Vault/index.md` and writes changes back to disk in <50ms
2. Two concurrent processes (Mada UI + external editor) edit the same file and converge without data loss or conflict files
3. Keystroke latency in the bare editor remains <16ms under continuous autosave

---

## Phase 1 — Infrastructure & Git

**Goal:** Establish the canonical repository structure, toolchain, and semantic registry so every subsequent agent operates from a shared, unambiguous context.

---

### 1.1 Repository Initialization

- [x] `git init` in `~/getmada` and push to GitHub under `senator-labs/getmada`
- [x] Add `.gitignore` covering: `target/`, `node_modules/`, `*.db`, `*.db-shm`, `*.db-wal`, `.env*`, `dist/`
- [x] Create `CODEOWNERS` assigning `@senatordev` as sole reviewer for `specs/` and `.semantic_registry/`
- [x] Commit `specs/core_specification.md` as the inaugural tracked file — this is the immutable contract
- [x] Tag the initial commit `v0.0.0.0.1` (Senator Versioning baseline — see `specs/versioning.md`)

**Verification:** `git log --oneline` shows at least one commit; remote `origin` is set and pushes cleanly.

---

### 1.2 Semantic Registry Scaffold

Build the full directory topology defined in the spec (§III.3.1) so agents always know where to look:

```
.semantic_registry/
├── product.md          # Business goals, personas, PLG strategy
├── tech-stack.md       # Mandatory Rust rules, CRDT constraints, banned patterns
└── DESIGN.md           # Visual tokens (placeholder for now — not Milestone 0 scope)
```

- [ ] Create `.semantic_registry/tech-stack.md` with the following hard rules:
  - **BANNED:** Node.js `fs` module in any WebView/frontend code
  - **MANDATORY:** All filesystem mutations must flow through a Tauri `invoke()` command
  - **MANDATORY:** SQLite must be opened with `PRAGMA journal_mode=WAL`
  - **MANDATORY:** Loro CRDT for all document state — no raw string replacement
  - **MANDATORY:** `notify` crate (not polling) for all file watch events
  - **PERFORMANCE CONTRACT:** File read/write round-trip <50ms; keystroke processing <16ms

- [ ] Create `.semantic_registry/product.md` summarizing Milestone 0 scope, banned features, and exit criteria (condense from spec §II.2.1)
- [ ] Create placeholder `.semantic_registry/DESIGN.md` noting design tokens are deferred to post-Milestone 0

**Verification:** An agent reading only `.semantic_registry/` can answer: "What crates are required? What is explicitly banned? What are the latency targets?"

---

### 1.3 Rust Toolchain & Node Environment

- [ ] Install Rust stable via `rustup` (target: `stable`, minimum version: 1.77)
- [ ] Install Tauri CLI v2: `cargo install tauri-cli --version "^2.0"`
- [ ] Install Node.js LTS (v20+) and `pnpm` (preferred over npm for workspace support)
- [ ] Verify: `cargo tauri --version`, `rustc --version`, `node --version` all succeed
- [ ] Add `rust-toolchain.toml` pinning the exact Rust channel to prevent agent environment drift:

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

---

### 1.4 CI Skeleton (GitHub Actions)

- [ ] Create `.github/workflows/ci.yml` with three jobs:
  1. `fmt` — `cargo fmt --check` (fail fast on unformatted Rust)
  2. `clippy` — `cargo clippy -- -D warnings` (zero warnings policy)
  3. `build` — `cargo tauri build --debug` (proves the app compiles)
- [ ] Set branch protection on `main`: require CI green before merge
- [ ] **Do not** add test jobs yet — no business logic to test at this phase

**Verification:** A green CI run on the initial scaffold commit.

---

### 1.5 Test Vault Fixture

- [ ] Create `~/Mada_Test_Vault/` (local only, never committed)
- [ ] Seed it with `index.md` containing 500 words of placeholder text across multiple paragraphs (enough to exercise the parser)
- [ ] Add `~/Mada_Test_Vault/` to global `.gitignore` or document in `README.md` that it is a local fixture

---

## Phase 2 — Tauri/Rust Base Shell

**Goal:** Validate Risk A — prove Tauri IPC can perform CRUD on `.md` files with <50ms latency and no browser sandbox interference.

---

### 2.1 Tauri Project Scaffold

- [ ] Run `cargo tauri init` inside `~/getmada` — accept defaults for WebView integration
- [ ] Confirm project structure:

```
getmada/
├── src/            # React + TypeScript frontend
├── src-tauri/
│   ├── src/
│   │   ├── main.rs         # Tauri application entry point
│   │   └── commands/       # IPC command handlers (one file per domain)
│   ├── Cargo.toml
│   └── tauri.conf.json
├── package.json
└── index.html
```

- [ ] Set `tauri.conf.json` `allowlist` to the minimum required surface: `fs` (read/write to `$HOME/Mada_Test_Vault` only), no network permissions
- [ ] Confirm `cargo tauri dev` opens a blank window with no errors in console

---

### 2.2 IPC Command Layer (Rust)

Implement the three commands needed for Milestone 0 — nothing more:

**`read_file`**
- [ ] Accept `path: String` parameter
- [ ] Validate path is within the hardcoded vault root (`~/Mada_Test_Vault`) — reject anything outside
- [ ] Return `Result<String, String>` (file content or error message)
- [ ] Measure and log round-trip time with `std::time::Instant`; assert <50ms in debug builds

**`write_file`**
- [ ] Accept `path: String`, `content: String`
- [ ] Perform atomic write: write to `<path>.tmp` then `std::fs::rename` into place (prevents partial writes)
- [ ] Set self-write exclusion flag immediately after rename (consumed by file watcher — see Phase 3)
- [ ] Return `Result<(), String>`

**`get_vault_path`**
- [ ] Return the hardcoded vault root as a `String`
- [ ] No parameters — this intentionally cannot be configured in Milestone 0

```rust
// src-tauri/src/commands/vault.rs — signature sketch
#[tauri::command]
pub async fn read_file(path: String) -> Result<String, String> { ... }

#[tauri::command]
pub async fn write_file(path: String, content: String) -> Result<(), String> { ... }

#[tauri::command]
pub fn get_vault_path() -> String { ... }
```

- [ ] Register all three commands in `main.rs` `tauri::Builder::invoke_handler`
- [ ] Write Rust unit tests for path validation logic (must reject `../` traversal)

**Verification (Risk A):** Call `read_file` and `write_file` from the Tauri dev console 100 times. Median round-trip <50ms. No panics. External editor changes to `index.md` are visible after next `read_file` call.

---

### 2.3 Frontend Scaffold (React + TypeScript)

- [ ] Bootstrap with Vite: `pnpm create vite src --template react-ts`
- [ ] Install Tailwind CSS (utility classes only — no component libraries at this stage)
- [ ] Install `@tauri-apps/api` for `invoke()` and `listen()` bindings
- [ ] Set `tsconfig.json` to `"strict": true` — no escape hatches

**App component — Milestone 0 UI (intentionally minimal):**
- [ ] On mount: call `invoke('get_vault_path')`, then `invoke('read_file', { path: vaultPath + '/index.md' })`, render content in a `<textarea>`
- [ ] On `textarea` `onChange`: debounce 200ms, then call `invoke('write_file', { path, content })`
- [ ] Status line at bottom: show last-saved timestamp and round-trip latency (pulled from Rust response)
- [ ] **No** Markdown rendering, syntax highlighting, or toolbar

**Explicitly confirm these are absent from the component tree:**
- [ ] No file tree sidebar
- [ ] No settings panel
- [ ] No auth flows
- [ ] No network calls

**Verification:** Type in the textarea, switch to a terminal, `cat ~/Mada_Test_Vault/index.md` — changes are persisted within 250ms of keyup.

---

### 2.4 Latency Profiling Harness

- [ ] Add a `MADA_PERF_LOG=1` environment variable gate that writes per-operation timing to `~/.mada_perf.jsonl`
- [ ] Each log entry: `{ "op": "write_file", "bytes": N, "duration_ms": N, "timestamp": ISO8601 }`
- [ ] Create `scripts/perf_report.sh` that reads the log and prints p50/p95/p99 latencies
- [ ] Run the harness for 60 seconds of continuous typing before declaring Phase 2 complete

**Verification (Risk C):** p95 write latency <50ms. No single write >100ms.

---

## Phase 3 — Local Storage Bridge

**Goal:** Validate Risk B — prove concurrent edits from Mada UI and an external editor converge mathematically via Loro CRDT, with SQLite as the fast query cache. This is the hardest risk and the core of Milestone 0.

---

### 3.1 File Watcher (notify crate)

- [ ] Add `notify = "6"` to `Cargo.toml`
- [ ] Spawn a dedicated watcher thread on app start watching `~/Mada_Test_Vault` recursively
- [ ] On `EventKind::Modify` for a `.md` file:
  1. Check self-write exclusion flag — if set, consume flag and return (ignore own writes)
  2. Calculate xxHash of new file content
  3. Compare against stored hash in SQLite; if identical, return (content unchanged, likely metadata event)
  4. If hash differs: emit Tauri event `vault://file-changed` with `{ path, new_hash }` to frontend
- [ ] Emit `vault://file-changed` events via `app_handle.emit_all()`
- [ ] Frontend listens with `listen('vault://file-changed', ...)` and triggers CRDT reconciliation (§3.3)

**Critical constraint:** The watcher must never trigger on its own `write_file` output. Self-write exclusion is not optional — it prevents the infinite loop described in spec §V.5.2.

**Verification:** Edit `index.md` in VS Code. Within 200ms, the Mada textarea reflects the change without any user action.

---

### 3.2 SQLite Index Layer (WAL Mode)

- [ ] Add `rusqlite = { version = "0.31", features = ["bundled"] }` to `Cargo.toml`
- [ ] On first launch, create `~/.local/share/mada/index.db` (OS cache dir, never inside the vault, never synced)
- [ ] Run on connection open:

```sql
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
```

- [ ] Create schema:

```sql
CREATE TABLE IF NOT EXISTS files (
    path        TEXT PRIMARY KEY,
    content_hash TEXT NOT NULL,
    word_count  INTEGER,
    indexed_at  INTEGER NOT NULL  -- Unix ms
);
```

- [ ] On `vault://file-changed` event: upsert the file record with new hash and word count
- [ ] On app startup: walk vault directory, upsert any file whose mtime is newer than its `indexed_at`
- [ ] Implement `rebuild_index()` Tauri command: drops all rows, re-walks entire vault — must complete in <10s for 10,000 files (measure and log)

**Verification:** After editing 20 files externally, call `rebuild_index()`. Query `SELECT COUNT(*) FROM files` — count matches filesystem. Total rebuild time logged and <10s.

---

### 3.3 Loro CRDT Integration

This is the validation of Risk B — the mathematical heart of Milestone 0.

- [ ] Add `loro = "1"` to `Cargo.toml` (Loro v1.0 stable)
- [ ] Maintain one `LoroDoc` instance per open file in a `HashMap<PathBuf, LoroDoc>` held in Tauri state
- [ ] On `read_file`: initialize `LoroDoc`, load file content as a `LoroText` node named `"content"`
- [ ] On each `write_file` (user keystroke batch): apply the delta as a CRDT operation against the in-memory `LoroDoc`, then export snapshot to disk (this is what gets written as the `.md` file — pure text, no CRDT metadata embedded in the file)
- [ ] On `vault://file-changed` (external edit detected):
  1. Read new file content from disk
  2. Diff against last known CRDT snapshot using Tree-sitter (see §3.4) to produce an operation set
  3. Apply external operations to `LoroDoc` — Loro's Fugue algorithm resolves ordering
  4. Export merged text and push to frontend via `vault://crdt-merged` event
  5. Write merged result back to disk (sets self-write exclusion flag)

**CRDT Contract:** The final file content must be identical regardless of operation order. Validate this with the concurrent edit test below.

**Verification (Risk B — Concurrent Edit Test):**
1. Open Mada, focus on `index.md` textarea
2. In a separate terminal: run `scripts/concurrent_edit_test.sh` which appends one line every 100ms for 10 seconds
3. Simultaneously type freely in the Mada textarea for the same 10 seconds
4. Stop both
5. Assert: `index.md` contains content from both sources — no lines from either source are missing, no `(Sync Conflict)` files exist, no `<<<<<<` merge markers

---

### 3.4 Tree-sitter AST Diff (Minimal)

For Milestone 0, Tree-sitter is used only to translate a brute file overwrite into a structured diff. Full fuzzy anchoring (spec §I.5) is deferred to post-Milestone 0.

- [ ] Add `tree-sitter = "0.22"` and `tree-sitter-markdown = "0.2"` to `Cargo.toml`
- [ ] Implement `diff_content(old: &str, new: &str) -> Vec<CrdtOperation>`:
  - Parse both strings with the Markdown grammar
  - Walk the AST diff at the paragraph/list-item level
  - Emit `Insert`, `Delete`, or `Retain` operations
- [ ] This function is called exclusively from the `vault://file-changed` handler — not on user keystrokes (those go direct to CRDT)
- [ ] Enforce: parsing must complete in <5ms for files up to 50KB (use `criterion` benchmark)

---

### 3.5 End-to-End Integration Smoke Test

- [ ] Create `scripts/milestone0_test.sh`:

```bash
#!/usr/bin/env bash
# Milestone 0 exit criteria validation
set -euo pipefail

VAULT="$HOME/Mada_Test_Vault"
FILE="$VAULT/index.md"

echo "=== M0 Test: File round-trip latency ==="
# Write 1000 bytes via invoke, measure time
# Assert median <50ms

echo "=== M0 Test: External edit detection ==="
# Start Mada dev build in background
# Echo a line to index.md from terminal
# Assert Mada emits vault://file-changed within 200ms

echo "=== M0 Test: Concurrent edit convergence ==="
# Run concurrent_edit_test.sh
# Assert no conflict files, no data loss

echo "=== M0 Test: SQLite WAL concurrent access ==="
# Open 10 parallel read queries while a write is in progress
# Assert zero 'database is locked' errors

echo "All Milestone 0 exit criteria PASSED"
```

- [ ] All four assertions must pass before Milestone 0 is declared complete

---

## Milestone 0 Completion Checklist

| # | Exit Criterion | Phase | Status |
|---|----------------|-------|--------|
| 1 | `cargo tauri dev` opens without errors | Phase 2 | |
| 2 | `read_file` median latency <50ms (100 runs) | Phase 2 | |
| 3 | `write_file` p95 latency <50ms (60s typing session) | Phase 2 | |
| 4 | External edit visible in UI within 200ms | Phase 3 | |
| 5 | Self-write exclusion prevents infinite watcher loop | Phase 3 | |
| 6 | SQLite WAL: zero lock errors under concurrent access | Phase 3 | |
| 7 | `rebuild_index()` completes <10s for 10,000 files | Phase 3 | |
| 8 | Concurrent edit test: both sources present, no conflicts | Phase 3 | |
| 9 | CI green on `main` (fmt + clippy + build) | Phase 1 | |
| 10 | `.semantic_registry/tech-stack.md` reviewed and accurate | Phase 1 | |

---

## What Is Explicitly Deferred

These are not forgotten — they are deliberately scheduled post-Milestone 0 to avoid validating the wrong thing:

- Markdown rendering (bold, italics, headers, code blocks)
- File navigation tree / sidebar
- `[[wikilink]]` resolution and backlinks
- Fuzzy block anchoring (Tree-sitter full implementation)
- AI / MCP / Ollama integrations
- Settings UI or user-configurable vault path
- Cloud sync, authentication, Obsidian Sync bridge
- Themes, fonts, design system tokens
- Mobile (Tauri Mobile is experimental — evaluate post-M0)

---

## Version Progression (Milestone 0)

Versioning follows the Senator Versioning system (`specs/versioning.md`): `[Major].[Minor].[Alpha/Patch].[Milestone].[Micro]`. All commits must use Conventional Commits (`feat:`, `fix:`, `chore:`, etc.).

| Phase | Scope | Version Range |
|-------|-------|---------------|
| Phase 1 | Repo, registry, toolchain, CI | `v0.0.0.0.1` → `v0.0.0.0.3` |
| Phase 2 | Tauri shell, IPC commands, bare editor | `v0.0.0.0.4` → `v0.0.0.0.7` |
| Phase 3 | File watcher, SQLite, Loro CRDT, concurrent test | `v0.0.0.0.8` → `v0.0.0.0.N` |
| **M0 complete** | **All exit criteria green — tag release** | **`v0.0.0.1.0`** |

Next review checkpoint: after Milestone 0 validation, reassess the CRDT performance data and decide whether Loro's Rust API surface is sufficient for the full outliner architecture before committing to Phase 4 (MVP Core PKM).

---

**Authority:** This roadmap is derived from and subordinate to `specs/core_specification.md`. Any conflict between this document and the spec resolves in favor of the spec. Changes here require a commit with explicit rationale.
