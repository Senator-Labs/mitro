---
type: core_specification
project: Mada
version: 1.0.0
status: canonical
authority_level: sovereign
last_updated: 2026-05-07
---

# Mada: Core Specification & Architectural Blueprint

**Document Type:** Single Source of Truth for All Development Agents
**Project:** Mada (Senator Labs)
**Status:** Foundation Established / Active Development
**Philosophy:** Risk-First, Local-First, Agent-Native

---

## Executive Summary

Mada is a next-generation, local-first Personal Knowledge Management (PKM) and workspace application designed explicitly as a shared runtime environment for both human users and autonomous AI agents. Born from the synthesis of Andrej Karpathy's "LLM Knowledge Base" philosophy and the critical lessons learned from the SaaS lock-in failures of Notion, Tana, and the database-migration controversies surrounding Logseq, Mada represents a fundamental architectural departure from legacy knowledge management paradigms.

**Core Mission:** Deliver an out-of-the-box, collaborative environment where pure `.md` (Markdown) files serve as the absolute, uncorrupted source of truth—enabling instantaneous local-first performance, complete data sovereignty, and native AI agent orchestration without the vendor lock-in, privacy erosion, or formatting corruption endemic to cloud-first platforms.

**Primary Target Market:** The prosumer developer demographic—solo founders, researchers, and power users who demand keyboard-first navigation, sub-50ms response times, and the freedom to run local AI models (via Ollama, LM Studio) without leaking intellectual property to external cloud providers.

**Strategic Positioning:** Mada aims to disrupt the existing PKM hegemony by combining:
- The local sovereignty and plain-text permanence of Obsidian
- The outliner precision and semantic richness of Tana/Roam Research
- The AI-native, agent-first workflows pioneered by Cursor and emerging platforms like Cabinet
- The uncompromising performance and minimal resource footprint of Tauri/Rust architectures

---

## I. Core Architecture: The Technical Foundation

### 1.1 Application Framework

**Decision:** Tauri 2.0 with Rust Backend

**Architectural Rationale:**
- **Rejection of Electron:** Traditional Electron-based PKM applications (Notion, Obsidian legacy builds) suffer from catastrophic memory bloat (150-400 MB idle RAM), slow startup times (2-5 seconds), and massive binary sizes (120-200 MB). For an application positioning itself as the "second brain" requiring instant cognitive availability, these metrics are unacceptable.

- **Tauri Superiority:** Tauri leverages the operating system's native WebView, resulting in:
  - Binary sizes: 3-10 MB (vs. 120-200 MB for Electron)
  - Idle memory consumption: 40-80 MB (vs. 150-400 MB)
  - Startup time: <200ms (vs. 2-5 seconds)
  - Maximum CPU and RAM availability for concurrent local AI model execution

- **Rust Backend Benefits:**
  - Memory safety guarantees at compile-time (zero data races in deterministic code)
  - Unparalleled performance for multi-threaded file system operations
  - Native integration with high-performance libraries: `notify` crate for file watching, Tree-sitter for incremental AST parsing, and direct FFI bindings to SQLite

**Technical Constraints:**
- The Rust backend operates via Inter-Process Communication (IPC) bridges, completely isolating the rendering layer from raw filesystem access to maintain security boundaries
- All file mutations must flow through Rust-validated command handlers to prevent WebView-originated exploits

### 1.2 Data Model: Markdown as Absolute Source of Truth

**Decision:** Pure, raw `.md` files are the database. No proprietary databases. No hidden formatting logic.

**Philosophical Foundation:**
- **Interoperability & Longevity:** If Mada ceases to exist, all user data remains eternally readable in any text editor on any platform, across any operating system, for decades to come.

- **Anti-SaaS Lock-in:** Prevents the catastrophic "Notion export corruption" problem where exporting data results in bloated, malformed files with broken formatting.

- **Agent-Friendly Architecture:** AI agents (Claude Code, local LLMs via Ollama) excel at reading and writing raw Markdown. A transparent file system enables agents to operate natively without complex API bridges or SDK abstractions.

**Implementation Architecture:**
The Markdown files live in a user-designated local directory. This directory can optionally be routed through:
- **Google Drive tunnel** (ChromeOS path: `/mnt/chromeos/GoogleDrive/MyDrive/Senator_Vault`) for automatic cloud backup
- **Git repository** for version control and multi-device synchronization
- **Obsidian Sync** for mobile fleet management (with selective sync to minimize bloat on lightweight devices)

**Critical Constraint:** All Markdown files must remain syntactically valid and human-readable at all times. No invisible UUID tags. No sidecar JSON files that break when files are renamed outside the application.

### 1.3 Synchronization & State Management: CRDT Architecture

**Decision:** Implement Conflict-Free Replicated Data Types (CRDTs) using the **Loro CRDT Library**

**Technical Justification:**

**Comparative Analysis:**

| CRDT Library | Algorithm | History Management | Rich-Text Merging | Memory Efficiency | Verdict for Mada |
|--------------|-----------|-------------------|-------------------|-------------------|-------------------|
| **Automerge v3** | Operation-based CRDT | Retains full edit history permanently | Basic text merging | Compressed columnar store | ❌ Rejected: Permanent history retention causes bloat for large vaults |
| **Yjs** | Sequence CRDT | History garbage collected | Basic text merging | Highly optimized | ⚠️ Acceptable but limited: 53-bit unsigned integer client IDs risk collision; prone to character interleaving anomalies |
| **Loro v1.0** | Event Graph Walker + Fugue | Separates OpLog from DocState | **Peritext-compliant style anchors** | Tombstone-free optimization | ✅ **Selected**: Prevents interleaving anomalies, maintains Markdown formatting integrity, scales without historical bloat |

**Loro's Critical Advantages:**
1. **Fugue Algorithm:** When concurrent text insertions occur at the same position (e.g., human types while AI agent simultaneously injects text), Fugue uses deterministic identifiers to maintain intended character order, preventing scrambled text.

2. **Style Anchors (Peritext Compliance):** If an AI agent bolds a phrase in Markdown (`**text**`) while a human simultaneously edits that phrase's content, Loro's style anchors ensure the merged result preserves both the new content AND the bold formatting without breaking Markdown syntax boundaries.

3. **Tombstone-Free Architecture:** Unlike traditional CRDTs that accumulate deletion "tombstones," Loro's architecture enables rapid synchronization and snapshotting without infinite historical bloat—critical for a database consisting of 100,000+ nodes and 1.6GB of Markdown.

**Agent-Native Race Condition Mitigation:**
- When the user types in the Windsurf IDE/Mada UI, each keystroke generates a timestamped CRDT operational delta
- When an autonomous AI script (e.g., Claude Code Agent Team member) brutally overwrites a `.md` file via OS-level file write, Mada's file watcher detects the change
- The Rust backend calculates the diff using Tree-sitter AST, translates the brute file modification into CRDT operations, and mathematically merges with the user's concurrent keystrokes
- **Result:** Characters are algorithmically interwoven, not overwritten—eliminating `(Sync Conflict)` files and data loss

### 1.4 Hybrid SQLite Projection Layer

**Decision:** Maintain an ephemeral, local SQLite database (with Write-Ahead Logging enabled) as a fast indexing and query layer

**Architectural Purpose:**
- **Problem:** Traversing 100,000+ `.md` files on every search query is computationally prohibitive and introduces unacceptable latency (5-30 seconds)
- **Solution:** SQLite acts as a **projection/cache layer**—a fast, queryable mirror of the Markdown truth

**Critical Constraints (Risk Mitigation):**
1. **SQLite is Ephemeral, Not Canonical:** If the SQLite database becomes corrupted (due to OS crashes, iCloud interference, or power failures), Mada must be capable of reconstructing the entire index from the Markdown files within seconds using multi-threaded Rust parsing.

2. **WAL Mode is Mandatory:** Write-Ahead Logging (WAL) must be enabled to allow concurrent readers and writers without triggering `database is locked` errors—essential when AI agents index files while the user navigates the UI.

3. **Content Hashing to Prevent Infinite Sync Loops:**
   - When the file watcher detects a Modify event, calculate a fast non-cryptographic hash (xxHash) of the file payload
   - Only trigger expensive I/O and parsing if the hash differs from the stored SQLite value
   - When Mada writes to disk, set a transient exclusion flag to ignore the self-generated watcher event

4. **Integration with cr-sqlite for CRDT-aware Relational State:** Consider integrating `cr-sqlite` extension to add multi-master replication capabilities to the SQLite layer itself, enabling eventual consistency across devices

### 1.5 Outliner Architecture: Fuzzy Anchoring Without UUID Pollution

**Core Challenge:** Enable block-level references and outliner precision (like Roam Research/Tana) WITHOUT polluting Markdown files with unreadable ID tags (like Obsidian's `^block123` syntax)

**Rejected Approaches:**

| Architecture Model | Mechanism | Advantages | Fatal Flaws |
|--------------------|-----------|------------|-------------|
| **Sidecar JSON** | Store `note.json` alongside `note.md` with UUID-to-AST mappings | Markdown stays 100% clean | Catastrophic failure when files are renamed/moved outside the app via OS file explorer—creates silent data corruption and de-facto vendor lock-in |
| **Pure SQLite Relations** | Store filename + exact line/character offset in SQLite | No filesystem clutter | Extremely fragile—breaks immediately when external editors insert lines above the target block |

**Selected Solution: Fuzzy Anchoring via Tree-sitter AST + Content Hashing**

**Mechanism:**
1. **Incremental Parsing with Tree-sitter:** When a Markdown file is opened or modified, Tree-sitter generates an Abstract Syntax Tree (AST) where each paragraph, list item, and heading is positioned in a hierarchical structure (e.g., `Root -> Section(H2) -> List -> ListItem(index: 2)`)

2. **Fuzzy Hash Generation:** When File B references a block in File A, Mada calculates a **layered fuzzy hash** containing:
   - Normalized text content of the block
   - Tree-sitter AST structural context (which heading section contains this block?)
   - Lexical anchors (5-word token sequences immediately before and after the block)

3. **Survival of External Edits:** When an AI agent adds 100 lines of text to the top of File A, all line numbers shift—but the fuzzy hash remains stable because:
   - The block's content hasn't changed
   - The AST structural relationship (block is still under the same H2 heading) persists
   - The surrounding lexical anchors remain intact

4. **Re-anchoring on Background Parse:** After Tree-sitter incrementally updates the AST, Mada's SQLite engine performs a similarity search using token-level matching or Levenshtein distance. If a candidate block exceeds a confidence threshold (e.g., 90%), the reference automatically "snaps back" without user intervention.

**Performance Constraint:** This algorithm is computationally expensive at scale. Multi-threaded Rust implementation with aggressive caching is mandatory to prevent UI stuttering when validating thousands of references.

---

## II. Functional Scope: MVP Feature Set

### 2.1 Milestone 0: The Engine Test (Risk-First Development)

**Philosophy:** Prove the core technical hypotheses BEFORE building UI polish, settings menus, or branding elements.

**Critical Technical Risks to Mitigate:**

**Risk A: Tauri/Rust File System Bridge**
- **Hypothesis:** Tauri and Rust can provide seamless, instantaneous read/write access to local `.md` files without browser sandbox limitations or Electron bloat
- **Test:** Build a basic Tauri backend that binds to a test vault directory and successfully performs CRUD operations on `.md` files with <50ms latency

**Risk B: CRDT Implementation on Plain Text**
- **Hypothesis:** Loro CRDT can merge concurrent edits (human in UI + AI agent via CLI writing to same file) without generating `(Sync Conflict)` files
- **Test:** Spawn two concurrent processes editing the same document and verify mathematical convergence

**Risk C: Editor-to-Disk Latency**
- **Hypothesis:** Maintain instantaneous typing feel while constantly pushing state changes to Rust backend and saving to disk
- **Test:** Connect a barebones frontend editor (ProseMirror/TipTap) to Rust backend and measure input latency during continuous autosave

**Milestone 0 Scope (Stripped-Down Prototype):**
- Blank, unstyled Tauri window
- Hardcoded path to local test folder (`~/Mada_Test_Vault`)
- Simple textarea loading `index.md`
- Real-time Rust backend updates to `index.md` as user types
- **Ultimate Test:** Open `index.md` in external editor (VS Code/Vim) while user types in Mada—changes from both sources must merge without data loss

**Explicitly Banned from Milestone 0:**
- Cloud synchronization or authentication
- File navigation trees/sidebars
- Markdown rendering (bold, italics, headers)
- AI integrations
- Settings pages or themes

### 2.2 MVP Feature Roadmap (Post-Engine Validation)

**Phase 1: Core PKM Functionality**
- File tree navigation with keyboard-first shortcuts (Cmd/Ctrl+K command palette)
- Markdown WYSIWYG editor with syntax highlighting
- Bidirectional `[[wikilinks]]` with instant backlink panel
- Full-text search across vault with fuzzy matching
- Daily notes with calendar navigation
- Tag system with hierarchical tag support

**Phase 2: Outliner & Block-Level Operations**
- Block-level references using Fuzzy Anchoring (no visible UUIDs)
- Drag-and-drop block reordering
- Block embeds (transclusion)
- Unlinked mentions auto-detection
- Zoom into blocks (focused editing mode)

**Phase 3: Agent-Native Infrastructure**
- Model Context Protocol (MCP) server integration
- Background agent workspace with isolated Git worktrees
- Automatic file indexing and semantic link suggestions
- AI-powered daily digest generation (summarizes vault activity)
- Critic-in-the-Loop review hooks (pre-commit validation)

**Phase 4: Collaboration & Sync**
- Git-backed synchronization with automatic commit/push
- Conflict resolution UI for merge conflicts
- End-to-end encrypted remote sync option (self-hosted or managed)
- Multi-device state synchronization via CRDT broadcast

---

## III. Operational Workflow: Agent-First Semantic Engineering

### 3.1 The Semantic Registry Paradigm

**Core Principle:** Reject inline code annotations. Externalize all semantic intent into pure Markdown files.

**Rationale:**
- **Problem with Jac-style Meaning-Typed Programming in Rust:** Embedding LLM prompt synthesis directly into Rust code via procedural macros creates:
  - Massive metaprogramming bloat (drastically increased compile times)
  - Violation of determinism (probabilistic model invocations inside mathematical execution pipeline)
  - Token inefficiency (models must parse complex macro syntax to extract semantic intent)

- **Solution: Decoupled Local Semantic Registry**
  - All semantic definitions, design rules, branding guidelines, and business logic live in structured Markdown files
  - Agents (Claude Code, Windsurf) read these files as persistent context
  - These files version-control in Git alongside code and sync via CRDT with the Markdown database

**Directory Topology:**

```
/getmada/
├── .claude/
│   ├── hooks.json                    # Critic-in-the-Loop intercept events
│   └── skills/                       # Reusable SOPs for agents
├── .semantic_registry/
│   ├── product.md                    # Business goals, user personas, core logic
│   ├── tech-stack.md                 # Rust memory rules, CRDT constraints
│   └── DESIGN.md                     # Visual system (YAML tokens + Markdown rationale)
├── tracks/
│   └── feature_x/
│       ├── spec.md                   # Immutable requirement document
│       └── plan.md                   # Executable checklist with verification checkpoints
├── src/                              # Pure, un-annotated Rust backend code
├── src-tauri/                        # IPC bridging logic
└── docs/                             # Human-readable documentation
```

### 3.2 Context-Driven Development Protocol

**Standard Operating Procedure for Agent-Orchestrated Development:**

**Phase 1: Context Establishment**
1. Define `DESIGN.md`:
   - YAML frontmatter: Exact hex codes, font families, spacing units
   - Markdown body: Rationale and contextual usage rules (prevents generic hallucinations)

2. Define `tech-stack.md`:
   - Explicitly ban Node.js filesystem modules in WebView
   - Mandate Tauri invoke commands for all OS operations
   - Specify exact Loro CRDT Rust crate parameters for Markdown synchronization

**Phase 2: Track Initialization**
1. Create new track: `tracks/crdt-implementation/`
2. Human writes natural language intent in `tracks/crdt-implementation/brief.md`
3. Invoke Claude Code: "Read `.semantic_registry/` and generate rigorous `spec.md` for CRDT implementation"
4. Agent generates `plan.md` with hierarchical task breakdown and explicit checkpoint markers

**Phase 3: Execution via Agent Teams**
1. Invoke Claude Code Agent Teams from terminal: `claude code --team --plan tracks/crdt-implementation/plan.md`
2. Lead Agent spawns specialized teammates into isolated Git worktrees:
   - Teammate A: Rust CRDT data structures
   - Teammate B: UI component updates matching `DESIGN.md`
3. Teammates check off tasks in `plan.md` as they complete work
4. Lead Agent calls Plane.so MCP server to transition issue tickets automatically

**Phase 4: Critic-in-the-Loop Review**
1. When primary agent attempts to exit, `.claude/hooks.json` intercepts
2. Hook script generates Git diff and prompts secondary Critic Agent (e.g., temperature-zero GPT-4)
3. Critic searches for:
   - Code shortcutting
   - Rust borrow checker violations
   - Deviations from `DESIGN.md` visual guidelines
4. Primary agent ingests critique and rewrites code
5. Only after Critic approval does the hook permit clean exit

### 3.3 The Critic-in-the-Loop Architecture

**Problem:** Autonomous agents exhibit "optimism bias"—hallucinating completion status, rubber-stamp approving teammate code, and shipping untested logic.

**Solution: Automated Adversarial Review**

**Implementation:**
```json
// .claude/hooks.json
{
  "exit": {
    "script": "./scripts/critic_review.sh",
    "blocking": true
  }
}
```

**Script Logic:**
1. Read local state file tracking review loop phase
2. If in "initial task phase," block agent exit
3. Generate comprehensive prompt payload:
   - Raw Git diff of proposed changes
   - Original `spec.md` requirements
   - Constraints from `tech-stack.md`
4. Route to specialized Critic Agent (separate LLM instance trained for adversarial analysis)
5. Critic outputs detailed Markdown report of structural flaws
6. Force primary agent to ingest critique and rewrite
7. Update state machine to "review complete" phase
8. On next exit attempt, permit clean shutdown

**Benefits:**
- Solo founder avoids manually reviewing thousands of lines of boilerplate
- Probabilistic LLM output collapses into deterministic, high-quality state before merging
- Secures integrity of local-first application against agent hallucinations

---

## IV. Technical Stack: Definitive Technology Selections

### 4.1 Core Stack

| Component | Technology | Justification |
|-----------|-----------|---------------|
| **Application Framework** | Tauri 2.0 | Sub-200ms startup, 40-80 MB idle RAM, 3-10 MB binaries |
| **Backend Language** | Rust | Memory safety, zero-cost abstractions, native threading performance |
| **Frontend Framework** | React + TypeScript | Mature ecosystem, component reusability, strong typing |
| **Editor Core** | ProseMirror or TipTap | Extensible document model, CRDT-compatible, production-proven |
| **CRDT Library** | Loro v1.0 | Fugue algorithm prevents interleaving, Peritext-compliant style anchors |
| **File Watcher** | `notify` crate (Rust) | Direct OS primitives (inotify/FSEvents), low CPU overhead |
| **AST Parser** | Tree-sitter | Incremental parsing, <5ms updates, industry-standard |
| **SQLite Extension** | cr-sqlite (optional) | Multi-master CRDT replication for eventual consistency |
| **Styling** | Tailwind CSS | Utility-first, minimal runtime overhead |
| **Design Tokens** | DESIGN.md (Google Stitch format) | Open-source, W3C-compliant, agent-readable |

### 4.2 AI Agent Integration Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Terminal Agent** | Claude Code (Opus 4.7) | Agent Teams, 200K context, 87.6% SWE-bench score |
| **Visual IDE** | Windsurf | Enterprise-scale indexing (100K+ files), RAG engine |
| **Local Model Runtime** | Ollama / LM Studio | Privacy-preserving inference (Llama 3, Mistral) |
| **Context Protocol** | Model Context Protocol (MCP) | Standardized agent-to-tool communication |
| **Issue Tracker** | Plane.so or lific | MCP-native, Git-backed project management |
| **Memory Layer** | PLUR.ai or AIVectorMemory | BM25 + vector embeddings, persistent context |

### 4.3 Deployment & Distribution

| Platform | Strategy |
|----------|----------|
| **macOS** | Tauri native bundle (.dmg) + Homebrew cask |
| **Windows** | Tauri native installer (.msi) + winget package |
| **Linux** | AppImage + Flatpak + AUR package |
| **Mobile (iOS/Android)** | Future: Tauri Mobile (currently experimental) |

---

## V. Development Principles & Constraints

### 5.1 Architectural Commandments

1. **Markdown is Sacred:** Never allow agent modifications that corrupt Markdown syntax or introduce invisible characters/tags
2. **Fail Fast, Fail Loud:** If CRDT merge fails, SQLite corrupts, or file watcher breaks, surface errors immediately—never silently degrade
3. **Offline-First Always:** Application must be 100% functional without network connectivity
4. **No Vendor Lock-in:** Users must be able to export/fork their entire vault at any time with zero data loss
5. **Agent Transparency:** Every agent action must be logged with attribution, timestamp, and diff preview before merging
6. **Performance as Feature:** Sub-50ms response to user input is non-negotiable—profile and optimize relentlessly

### 5.2 Risk Mitigation Strategies

**Risk:** SQLite corruption due to iCloud/Dropbox interference
**Mitigation:**
- Store SQLite database in OS-specific cache directory (excluded from cloud sync)
- Implement fast SQLite rebuild from Markdown source on corruption detection
- Warn users against placing vault in actively syncing cloud folders (recommend Git-based sync instead)

**Risk:** Infinite file watcher sync loops
**Mitigation:**
- Content-hash every file before triggering parse/index operations
- Suppress watcher events for self-generated writes using transient exclusion flags
- Implement exponential backoff if loop detected (>10 events/second on single file)

**Risk:** Agent "hallucination contamination" of knowledge base
**Mitigation:**
- Implement Critic-in-the-Loop automated review before merging agent changes
- Require human approval for destructive operations (file deletion, mass refactoring)
- Maintain immutable Git history for rollback capability
- Optional: Separate "messy vault" (agent playground) from "clean vault" (human-curated truth)

**Risk:** Race conditions in concurrent agent + human edits
**Mitigation:**
- Loro CRDT mathematical convergence guarantees (no locking required)
- Git worktree isolation for Agent Teams (each teammate operates in separate branch)
- Real-time diff preview in UI before accepting agent-proposed changes

**Risk:** Performance degradation with 100K+ files
**Mitigation:**
- Lazy-load file tree (virtualized scrolling)
- Index only modified files (incremental indexing via file watcher)
- Parallelize SQLite queries across CPU cores
- Implement aggressive caching of Tree-sitter ASTs

---

## VI. Success Metrics & PLG Strategy

### 6.1 Technical Performance Targets (MVP)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Cold Start Time** | <200ms | Time from app launch to interactive UI |
| **Idle Memory Usage** | <80 MB | Activity Monitor/Task Manager after 5 min idle |
| **Keystroke Latency** | <16ms (60fps) | High-speed camera frame analysis |
| **Full-Vault Search** | <500ms | 10,000 files, keyword query to results display |
| **File Save Latency** | <50ms | Write to disk + CRDT broadcast |
| **SQLite Rebuild Speed** | <10s | 100,000 files, full index reconstruction |

### 6.2 Product-Led Growth (PLG) Strategy

**Model:** Cursor-inspired freemium with local-first core

**Free Tier:**
- Unlimited local vaults
- Full Markdown editing and linking
- Basic AI features (local models via Ollama)
- Community support

**Pro Tier ($15-25/month):**
- Premium AI models (Claude Opus, GPT-4)
- Managed E2E encrypted sync
- Priority support
- Advanced agent orchestration features

**Enterprise Tier (Custom Pricing):**
- Self-hosted sync infrastructure
- SSO/SAML integration
- Audit logging and compliance features
- Dedicated support + SLA

**Go-to-Market:**
1. **Launch on Product Hunt** with focus on "Obsidian + Cursor for Knowledge Management"
2. **Viral content strategy:** Developer blog posts on local-first architecture, CRDT implementation
3. **Strategic integrations:** MCP server ecosystem, Obsidian plugin directory
4. **Community-led growth:** Open-source semantic registry templates, public DESIGN.md examples

---

## VII. Competitive Differentiation Matrix

| Feature | Mada | Obsidian | Notion | Tana | Logseq (DB) |
|---------|-------|----------|--------|------|-------------|
| **Local-First** | ✅ Core | ✅ Yes | ❌ Cloud-only | ❌ Cloud-only | ⚠️ SQLite (opaque) |
| **Pure Markdown** | ✅ Forever | ✅ Yes | ❌ Proprietary | ❌ Proprietary | ❌ Migrating away |
| **Outliner Mode** | ✅ Fuzzy Anchoring | ⚠️ UUID pollution | ✅ Blocks | ✅ Nodes | ✅ Blocks |
| **CRDT Sync** | ✅ Loro | ❌ File-based | ❌ N/A | ❌ Proprietary | ⚠️ Limited |
| **Agent-Native** | ✅ MCP + Teams | ⚠️ Plugins | ⚠️ Notion AI | ⚠️ Tana AI | ❌ No |
| **Performance** | ✅ <200ms start | ⚠️ Plugin-dependent | ❌ Network latency | ❌ Network latency | ⚠️ Varies |
| **Data Sovereignty** | ✅ Absolute | ✅ Yes | ❌ Vendor-locked | ❌ Vendor-locked | ⚠️ Opaque DB |

---

## VIII. Open Questions & Future Research

### 8.1 Architectural Decisions Pending Validation

1. **Mobile Strategy:** Tauri Mobile is experimental—contingency plan if iOS/Android support delayed?
2. **GPUI vs. Tauri:** Should we explore pure Rust GPU rendering (Zed model) for maximum performance, despite higher dev cost?
3. **P2P Sync:** Investigate Anytype's any-sync protocol for true peer-to-peer CRDT synchronization without central server
4. **Vector Embeddings:** Local semantic search via embeddings (Chroma, Qdrant) vs. pure BM25 lexical search—cost/benefit analysis?

### 8.2 Compliance & Security Roadmap

- GDPR compliance audit for European users
- SOC 2 Type II certification for enterprise tier
- Penetration testing of IPC boundaries and agent sandboxing
- Formal threat model for indirect prompt injection attacks

---

## IX. Conclusion: The Mada Mandate

Mada exists to solve the fundamental betrayal of modern knowledge work: the forced choice between cloud collaboration convenience and local data sovereignty. We reject this false dichotomy. Through rigorous application of Conflict-Free Replicated Data Types, agent-native semantic engineering, and uncompromising local-first architecture, Mada delivers instantaneous performance, absolute data ownership, and collaborative intelligence without vendor lock-in.

This specification serves as the immutable contract between human architects and autonomous coding agents. Every technical decision documented herein prioritizes:

1. **User Sovereignty:** Their data, their machine, their control—forever
2. **Mathematical Correctness:** CRDT guarantees, memory safety, deterministic behavior
3. **Agent Collaboration:** AI as tireless teammate, human as final authority
4. **Long-Term Viability:** Plain text survives companies, protocols, and platforms

The path forward is clear. The technology stack is proven. The market demand is validated by Cursor's $1B ARR trajectory and the exodus from Logseq's database migration.

Mada will be built. This specification is the map. Now we execute.

---

**Document Authority:** This specification supersedes all prior architectural discussions. All coding agents must validate their work against these principles before merging.

**Revision Protocol:** Changes to this specification require explicit human approval and must be versioned in Git with detailed rationale in commit messages.

**Last Updated:** 2026-04-25
**Next Review:** After Milestone 0 validation (estimated 2-3 weeks)
