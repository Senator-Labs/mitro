---
type: product_context
project: Mada
status: canonical
authority_level: sovereign
last_updated: 2026-05-07
---

# Mada — Product Context & Business Logic

<context>
This document defines the **business goals, user personas, and product strategy** for the Mada engine. All feature decisions, UX choices, and roadmap priorities must align with these principles. Condensed from `specs/core_specification.md` §II.2.1, §VI. Authority: the spec supersedes this file.
</context>

---

## Mission

<context type="mission">
Deliver an out-of-the-box, collaborative environment where pure `.md` files serve as the absolute, uncorrupted source of truth — enabling instantaneous local-first performance, complete data sovereignty, and native AI agent orchestration without vendor lock-in, privacy erosion, or formatting corruption endemic to cloud-first platforms.
</context>

---

## Target Persona

<context type="user_persona">

**The Prosumer Developer**

- Solo founders, researchers, and power users
- Demand keyboard-first navigation and sub-50ms response times
- Require freedom to run local AI models (Ollama, LM Studio) without leaking IP to cloud providers
- Value plain-text permanence and full data ownership over convenience features

</context>

---

## Strategic Positioning

<context type="competitive_positioning">

Mada combines:

| Pillar | Reference Product |
|--------|------------------|
| Local sovereignty + plain-text permanence | Obsidian |
| Outliner precision + semantic richness | Tana / Roam Research |
| AI-native, agent-first workflows | Cursor / Cabinet |
| Uncompromising performance + minimal footprint | Tauri / Rust |

</context>

---

## Milestone 0 — Engine Test (Current Scope)

<context type="milestone_philosophy">
**Philosophy:** Risk-First. Prove the three core technical hypotheses before any UI polish, branding, or feature work.
</context>

### Three Critical Risks to Mitigate

<rules type="risk_validation">

| Risk | Hypothesis | Pass Condition |
|------|-----------|---------------|
| **A — Tauri/Rust FS Bridge** | Tauri+Rust can perform CRUD on `.md` files without browser sandbox limitations or Electron bloat | Read/write round-trip <50ms (100 runs) |
| **B — CRDT on Plain Text** | Loro CRDT can merge concurrent edits (human in UI + AI agent via CLI on same file) without `(Sync Conflict)` files | Both edit sources present in final file; no conflict markers |
| **C — Editor-to-Disk Latency** | Maintain instantaneous typing feel during continuous autosave to Rust backend | p95 write latency <50ms over 60s typing session |

</rules>

### Milestone 0 Scope (Stripped-Down Prototype)

<mandatory_patterns type="m0_scope">

- Blank, unstyled Tauri window
- Hardcoded vault path: `~/Mada_Test_Vault`
- Single `<textarea>` loading `index.md`
- Real-time Rust backend writes as user types
- External editor (VS Code/Vim) edits same file concurrently → changes must merge without data loss

</mandatory_patterns>

### Milestone 0 Exit Criteria

<rules type="exit_criteria">

| # | Criterion | Phase |
|---|-----------|-------|
| 1 | `cargo tauri dev` opens without errors | Phase 2 |
| 2 | `read_file` median latency <50ms (100 runs) | Phase 2 |
| 3 | `write_file` p95 latency <50ms (60s typing session) | Phase 2 |
| 4 | External edit visible in UI within 200ms | Phase 3 |
| 5 | Self-write exclusion prevents infinite watcher loop | Phase 3 |
| 6 | SQLite WAL: zero lock errors under concurrent access | Phase 3 |
| 7 | `rebuild_index()` completes <10s for 10,000 files | Phase 3 |
| 8 | Concurrent edit test: both sources present, no conflicts | Phase 3 |
| 9 | CI green on `main` (fmt + clippy + build) | Phase 1 |
| 10 | `.semantic_registry/tech-stack.md` reviewed and accurate | Phase 1 |

</rules>

### Explicitly Banned from Milestone 0

<banned_practices type="m0_scope">

These are deferred — not forgotten. They are scheduled post-Milestone 0 to avoid validating the wrong thing.

- Cloud synchronization or authentication
- File navigation trees / sidebars
- Markdown rendering (bold, italics, headers, code blocks)
- AI / MCP / Ollama integrations
- Settings pages, themes, or user-configurable vault path
- `[[wikilink]]` resolution and backlinks
- Fuzzy block anchoring (full Tree-sitter implementation)
- Mobile support (Tauri Mobile is experimental)

</banned_practices>

---

## Post-Milestone 0 MVP Roadmap

<context type="roadmap">

| Phase | Scope |
|-------|-------|
| **Phase 1 (Core PKM)** | File tree, WYSIWYG editor, wikilinks, full-text search, daily notes, tag system |
| **Phase 2 (Outliner)** | Block references (fuzzy anchoring), drag-and-drop, transclusion, unlinked mentions |
| **Phase 3 (Agent-Native)** | MCP server, background agent worktrees, semantic link suggestions, Critic-in-the-Loop |
| **Phase 4 (Sync)** | Git-backed sync, conflict resolution UI, E2E encrypted remote sync, CRDT broadcast |

</context>

---

## Performance Targets (MVP)

<rules type="performance">

| Metric | Target |
|--------|--------|
| Cold start time | <200ms |
| Idle memory usage | <80 MB |
| Keystroke latency | <16ms (60 fps) |
| Full-vault search | <500ms (10,000 files) |
| File save latency | <50ms |
| SQLite rebuild speed | <10s (100,000 files) |

</rules>

---

## PLG Strategy

<context type="business_model">

**Model:** Cursor-inspired freemium with local-first core.

| Tier | Price | Key Features |
|------|-------|-------------|
| **Free** | $0 | Unlimited local vaults, full Markdown editing, local AI (Ollama), community support |
| **Pro** | $15–25/mo | Premium AI models, managed E2E encrypted sync, advanced agent orchestration |
| **Enterprise** | Custom | Self-hosted sync, SSO/SAML, audit logging, dedicated SLA |

**Go-to-Market:**
1. Product Hunt launch — "Obsidian + Cursor for Knowledge Management"
2. Developer blog: local-first architecture, CRDT implementation deep-dives
3. MCP server ecosystem + Obsidian plugin directory integrations
4. Open-source semantic registry templates and public `DESIGN.md` examples

</context>

---

## Architectural Commandments

<rules type="core_principles">

1. **Markdown is Sacred** — never corrupt syntax or introduce invisible characters/UUID tags
2. **Fail Fast, Fail Loud** — surface errors immediately; never silently degrade
3. **Offline-First Always** — 100% functional without network connectivity
4. **No Vendor Lock-in** — full vault export at any time with zero data loss
5. **Agent Transparency** — every agent action logged with attribution, timestamp, and diff preview
6. **Performance as Feature** — sub-50ms response to user input is non-negotiable

</rules>

---

**Authority:** This document is canonical for product decisions. Technical implementation details defer to `specs/core_specification.md` and `.semantic_registry/tech-stack.md`. Revisions require human approval and a `docs(registry):` commit.
