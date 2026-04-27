---
type: versioning_spec
project: Mitro
version: 1.0.0
status: canonical
authority_level: sovereign
last_updated: 2026-04-27
---

# Senator Versioning — Specification

**Document Type:** Authoritative versioning standard for all Mitro releases and agent-generated commits
**Scope:** All source files, tagged releases, CI automation, and agent commit messages in `senator-labs/mitro`

---

## 1. Version Format

```
[Major].[Minor].[Alpha/Patch].[Milestone].[Micro]
```

All five digits are non-negative integers. The canonical string representation uses no prefix unless explicitly tagging a Git release, in which case the `v` prefix is used (e.g., `v0.0.0.1.0`).

| Position | Name | Meaning |
|----------|------|---------|
| 0 | **Major** | Incompatible architectural breaks — data model changes that require vault migration |
| 1 | **Minor** | Backward-compatible feature additions visible to end users |
| 2 | **Alpha/Patch** | Pre-release iterations within a minor version, or backward-compatible bug fixes post-release |
| 3 | **Milestone** | Completion of a defined Milestone (M0, M1, M2…) as declared in `ROADMAP.md` |
| 4 | **Micro** | Incremental commits within a milestone: individual tasks, fixes, or chores |

---

## 2. Reset Rule

**When a higher-level digit is bumped, all lower digits reset to 0.**

This rule is strict and has no exceptions.

| Before | Event | After |
|--------|-------|-------|
| `0.0.0.0.9` | Milestone 0 complete | `0.0.0.1.0` |
| `0.0.0.1.4` | Milestone 1 complete | `0.0.0.2.0` |
| `0.0.1.3.2` | Minor feature shipped | `0.1.0.0.0` |
| `0.1.2.1.7` | Breaking architectural change | `1.0.0.0.0` |

The Micro digit (`[4]`) increments with each qualifying commit inside a milestone. The Milestone digit (`[3]`) bumps only when the milestone exit checklist in `ROADMAP.md` is fully satisfied.

---

## 3. Current Baseline

| State | Version |
|-------|---------|
| Repository initialized, spec committed | `v0.0.0.0.1` |
| Milestone 0 complete (all exit criteria green) | `v0.0.0.1.0` |

---

## 4. Conventional Commits — Mandatory

All commits from human contributors and autonomous agents **must** use the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This is a hard requirement — CI will reject commits that do not conform once the lint hook is in place.

### 4.1 Required Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 4.2 Permitted Types

| Type | When to Use | Version Signal |
|------|-------------|----------------|
| `feat` | New user-facing functionality | Minor bump candidate |
| `fix` | Bug fix in existing functionality | Patch/Micro bump |
| `chore` | Tooling, dependency updates, config — no production logic change | Micro bump |
| `test` | Adding or updating tests only | Micro bump |
| `docs` | Documentation only (specs, registry, README) | Micro bump |
| `refactor` | Code restructuring with no behavior change | Micro bump |
| `perf` | Performance improvement with measurable result | Micro bump |
| `ci` | Changes to CI/CD configuration | Micro bump |
| `build` | Changes to build system or external dependencies | Micro bump |
| `revert` | Reverts a previous commit | Micro bump |

### 4.3 Breaking Changes

Append `!` to any type to signal a breaking change:

```
feat!: migrate vault format to v2 schema
```

A `!` commit is the signal to bump the Major digit. It must include a `BREAKING CHANGE:` footer explaining the migration path.

### 4.4 Scope

The optional scope names the subsystem affected. Permitted scopes for Mitro:

| Scope | Subsystem |
|-------|-----------|
| `ipc` | Tauri IPC command layer |
| `crdt` | Loro CRDT integration |
| `watcher` | `notify` file watcher |
| `sqlite` | SQLite index layer |
| `editor` | Frontend editor component |
| `registry` | Semantic registry files |
| `ci` | CI/CD pipeline |
| `spec` | Specification documents |

Examples:

```
feat(ipc): add write_file command with atomic rename
fix(watcher): prevent self-write loop via exclusion flag
chore(ci): add clippy job to GitHub Actions workflow
docs(spec): add Senator Versioning specification
test(crdt): add concurrent edit convergence assertion
```

### 4.5 Agent Commit Requirements

Autonomous agents (Claude Code, Windsurf) **must** include a `Co-Authored-By` trailer in every commit:

```
Co-Authored-By: Claude Code <noreply@anthropic.com>
```

Commits produced without a valid Conventional Commits type prefix will be flagged by the Critic-in-the-Loop hook and must be rewritten before merge.

---

## 5. Tagging Protocol

Git tags are created only at Milestone boundaries and at public release points:

| Tag Pattern | Trigger |
|-------------|---------|
| `v0.0.0.M.0` | Milestone M complete — all exit criteria in `ROADMAP.md` satisfied |
| `v0.N.0.0.0` | Minor release — feature set announced publicly |
| `v1.0.0.0.0` | Major release — production-ready, breaking change from prior series |

Tags are signed (`git tag -s`) and pushed explicitly — never created by automated agents without human approval.

---

## 6. Automation Readiness

The five-digit format and mandatory Conventional Commits are designed to support future automated version bumping via a tool such as `release-please` or a custom Rust CLI. The automation rules map as:

- `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`, `build` → increment Micro `[4]`
- `feat` → increment Milestone `[3]`, reset Micro
- `feat!` / `BREAKING CHANGE:` → increment Major `[0]`, reset all lower digits

These rules are not yet enforced by CI. They are documented here so the automation implementation has an unambiguous specification to target.

---

**Authority:** This document is canonical. Conflicts between commit practice and this spec resolve in favor of this spec. Revision requires explicit human approval and a `docs(spec):` commit on `main`.
