# Mitro Tech Stack

A semantic overview of the core technologies powering the Mitro engine.

---

## Core Engine

- **Language:** Rust
- **Rationale:** High performance and memory safety without a garbage collector. Ideal for a long-running, resource-efficient local engine.

---

## Database & Sync Layer

- **Database:** SQLite
- **Sync Strategy:** CRDTs (Conflict-free Replicated Data Types)
- **Rationale:** SQLite provides a lightweight, embedded, zero-configuration database. CRDTs enable conflict-free merging of distributed state, supporting offline-first and multi-device workflows.

---

## Data Format

- **Format:** Local-first Markdown (`.md`)
- **Rationale:** Human-readable, plain-text, version-control friendly. Keeps user data portable and fully owned by the user.

---

## Agent Interface

- **Tooling:** Windsurf / Claude Code CLI
- **Rationale:** AI-assisted development environment for agentic workflows, semantic context management, and accelerated iteration on the Mitro engine.

---

## Summary Table

| Layer            | Technology                  | Key Property                    |
|------------------|-----------------------------|---------------------------------|
| Core Engine      | Rust                        | Performance, memory safety      |
| Database         | SQLite                      | Embedded, zero-config           |
| Sync             | CRDTs                       | Conflict-free distributed state |
| Data Format      | Local-first Markdown (`.md`)| Portable, human-readable        |
| Agent Interface  | Windsurf / Claude Code CLI  | Agentic, AI-assisted dev        |
