---
type: registry_index
project: Mada
status: canonical
authority_level: sovereign
last_updated: 2026-05-07
---

# Semantic Registry — Index

<context>
This directory contains the **agent-readable semantic context** for the Mada project. All autonomous agents and human developers must read these files before making code changes. These documents define the immutable constraints, business logic, and architectural principles that govern all development work.
</context>

---

## Registry Structure

<context type="directory_map">

```
.semantic_registry/
├── README.md                    # This file — registry index and navigation
├── DESIGN.md                    # Visual design tokens (placeholder until post-M0)
├── product.md                   # Business goals, personas, PLG strategy
├── tech-stack.md                # Mandatory tech patterns and banned practices
├── 01_roles/                    # Agent role definitions (future)
├── 02_context/
│   └── STORAGE_POLICY.md        # Brain/Brawn separation policy
├── 03_skills/
│   └── index_obsidian.md        # Agent skill: Index Obsidian vault
└── 04_workflows/                # Reusable agent workflows (future)
```

</context>

---

## Core Registry Files

<mandatory_patterns type="reading_order">

### 1. `tech-stack.md` — Technical Foundation
- **Purpose:** Defines the immutable technical stack and hard constraints
- **Contains:** Mandatory patterns, banned practices, performance targets
- **Read first if:** Writing code, reviewing PRs, or validating architecture
- **Authority:** Sovereign — supersedes verbal instructions

### 2. `product.md` — Business Logic & Strategy
- **Purpose:** Defines business goals, user personas, and product scope
- **Contains:** Milestone 0 exit criteria, roadmap phases, PLG strategy
- **Read first if:** Making feature decisions, prioritizing work, or scoping tasks
- **Authority:** Canonical for product decisions

### 3. `DESIGN.md` — Visual Design System
- **Purpose:** Defines visual design tokens and UI constraints
- **Contains:** M0 UI contract (active), design tokens (placeholder)
- **Read first if:** Building UI components or applying styling
- **Authority:** Deferred until post-M0, then becomes canonical
- **Status:** Placeholder — no visual polish allowed in Milestone 0

</mandatory_patterns>

---

## Supporting Context Files

<context type="supplementary">

### `02_context/STORAGE_POLICY.md`
- **Purpose:** Defines Brain (knowledge) vs. Brawn (codebase) separation
- **Brain Path:** `/mnt/chromeos/GoogleDrive/MyDrive/Senator_Vault/Mada/`
- **Brawn Path:** `~/getmada` (this repository)
- **Cross-Context Rule:** Agents may read from Brain to inform Brawn development

### `03_skills/index_obsidian.md`
- **Purpose:** Agent skill for indexing Obsidian vault documentation
- **Use Case:** Synthesizing project briefs into canonical specifications

</context>

---

## Canonical Specifications (Outside Registry)

<context type="external_specs">

These files live outside `.semantic_registry/` but are part of the semantic context:

### `specs/core_specification.md`
- **Authority:** Sovereign — the single source of truth for all development
- **Length:** 519 lines of architectural detail
- **Supersedes:** All other documents in case of conflict

### `specs/versioning.md`
- **Authority:** Canonical for version numbering and commit conventions
- **Format:** Senator Versioning (5-digit: Major.Minor.Patch.Milestone.Micro)
- **Enforcement:** Conventional Commits mandatory for all commits

### `ROADMAP.md`
- **Authority:** Execution-level — defines Milestone 0 phases and tasks
- **Status:** Active — Phase 1.2 in progress
- **Subordinate to:** `specs/core_specification.md`

</context>

---

## Agent Usage Protocol

<rules type="agent_workflow">

### Before Writing Code
1. Read `tech-stack.md` for mandatory patterns and banned practices
2. Read `product.md` for feature scope and exit criteria
3. Read `specs/core_specification.md` for architectural context
4. Read `ROADMAP.md` for current phase and task status

### Before Committing
1. Verify no banned practices from `tech-stack.md`
2. Verify all mandatory patterns followed
3. Use Conventional Commits format (see `specs/versioning.md`)
4. Run `cargo fmt` and `cargo clippy` (zero warnings policy)

### When Uncertain
1. If a constraint conflicts with a requirement → ask human for clarification
2. If a file is missing from the registry → ask before creating
3. If a pattern is ambiguous → prefer the most conservative interpretation

### Critic-in-the-Loop
1. All code must pass adversarial review before merge
2. Deviations from registry require explicit human approval
3. Breaking changes require `feat!:` commit with `BREAKING CHANGE:` footer

</rules>

---

## Hard Rules Summary

<rules type="quick_reference">

### Stack
- **Framework:** Tauri 2.0 + Rust (edition 2024)
- **Data:** Local-first pure `.md` files (no UUID injection)
- **Database:** SQLite WAL (ephemeral cache only)
- **Sync:** Loro CRDT (Fugue algorithm)
- **Parser:** Tree-sitter (incremental, <5ms)
- **Frontend:** React + TypeScript (strict mode)

### AI Integration
- **Runtime:** Zero-Token local inference (Ollama/LM Studio)
- **Protocol:** Model Context Protocol (MCP)
- **Constraint:** No cloud API calls without explicit user consent

### UX
- **Experience:** Block-based outliner (Tana-style)
- **Rendering:** Virtual blocks from nested Markdown lists
- **Constraint:** No UUID pollution in Markdown files

### Performance
- **Cold Start:** <200ms
- **Idle Memory:** <80MB
- **Keystroke Latency:** <16ms (60fps)
- **File I/O:** <50ms (p95)

</rules>

---

## Versioning & Commits

<rules type="versioning">

### Senator Versioning Format
```
[Major].[Minor].[Patch].[Milestone].[Micro]
```

### Current Version
- **Baseline:** `v0.0.0.0.1` (repository initialized)
- **Target:** `v0.0.0.1.0` (Milestone 0 complete)

### Conventional Commits (Mandatory)
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Permitted types:** `feat`, `fix`, `chore`, `test`, `docs`, `refactor`, `perf`, `ci`, `build`, `revert`

**Breaking changes:** Append `!` to type (e.g., `feat!:`) and include `BREAKING CHANGE:` footer

</rules>

---

## Registry Maintenance

<rules type="maintenance">

### Adding New Files
1. Create file in appropriate subdirectory (`01_roles/`, `02_context/`, etc.)
2. Add YAML frontmatter with `type`, `project`, `status`, `authority_level`, `last_updated`
3. Use XML tags (`<context>`, `<rules>`, `<mandatory_patterns>`, `<banned_practices>`)
4. Update this README.md index
5. Commit with `docs(registry): add <filename>`

### Updating Existing Files
1. Update `last_updated` in YAML frontmatter
2. Maintain XML structure consistency
3. Commit with `docs(registry): update <filename> - <reason>`
4. Requires human approval for authority-level changes

### Deprecating Files
1. Move to `.semantic_registry/.archive/`
2. Update this README.md to remove reference
3. Commit with `docs(registry): archive <filename> - <reason>`

</rules>

---

**Authority:** This index is canonical for navigating the semantic registry. All registry files use strict XML tagging for maximum agent readability. Conflicts between registry files resolve in favor of `specs/core_specification.md`.

**Last Updated:** 2026-05-07  
**Maintainer:** @senatordev  
**Status:** Active — Phase 1.2 (Semantic Registry Refactor) Complete
