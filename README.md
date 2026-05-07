# Mada
The Agent-Native workspace. Local .md files as the absolute source of truth.

*Born on April 24, 2026.*

Mada is an open-source, local-first Personal Knowledge Management (PKM) engine and collaborative outliner. It is built on the philosophy that your data should never be held hostage in a proprietary SaaS database. 

In the era of autonomous AI agents and "Idea Files", agents need a true home. Mada provides this by treating pure local `.md` files as the absolute source of truth, while a high-performance SQLite/Rust backend acts as a seamless mirror for block-based editing and collaborative multiplayer.

### The Core Architecture (v0.0.0.0.1 - Milestone 0 in Progress)
* **File-First:** Your vault is just a folder of Markdown files.
* **Agent-Native:** External AI scripts can edit your files simultaneously without causing conflict copies, powered by local CRDTs.
* **Lightning Fast:** Built with Tauri v2 and Rust.

### Documentation
* **[Core Specification](specs/core_specification.md)** — Single source of truth for all development
* **[Versioning System](specs/versioning.md)** — Senator Versioning (5-digit semantic versioning)
* **[Roadmap](ROADMAP.md)** — Milestone 0 phases and exit criteria
* **[Semantic Registry](.semantic_registry/README.md)** — Agent-readable context and constraints

*Maintained by the architects at [Senator Labs](https://github.com/senator-labs).*
