---
type: design_tokens
project: Mada
format: Google Stitch (W3C-compliant)
status: placeholder
milestone_scope: post-Milestone-0
last_updated: 2026-05-07
authority_level: deferred
note: >
  Visual design tokens are intentionally deferred until after Milestone 0 validation.
  This file is a structural placeholder. Do NOT implement visual polish, themes, or
  component libraries until all three Milestone 0 exit risks (A, B, C) are resolved.
  See product.md and specs/core_specification.md §II.2.1 for banned M0 features.
---

# Mada — Design System

<context type="status_warning">
**STATUS: PLACEHOLDER — Milestone 0 Scope**

Design tokens, color palette, typography, and component guidelines are deferred to post-Milestone 0. Agents must not implement any visual styling beyond what the bare Milestone 0 UI contract specifies below.
</context>

---

## Milestone 0 UI Contract (Currently Active)

<mandatory_patterns type="m0_ui">

This is the **only** UI specification in force until all Milestone 0 exit criteria are green.

```
┌─────────────────────────────────────────────────────┐
│  Mada — Milestone 0 Prototype                      │
│─────────────────────────────────────────────────────│
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │                                               │  │
│  │   <textarea> — index.md content              │  │
│  │   (unstyled, full viewport height)           │  │
│  │                                               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  Last saved: 14:23:01 · Round-trip: 12ms            │
└─────────────────────────────────────────────────────┘
```

### What is permitted in M0 UI

- Plain `<textarea>` element, no styling beyond browser default
- Single-line status bar at bottom: last-saved timestamp + round-trip latency (ms)
- Tailwind CSS installed but **no utility classes applied** — ready for post-M0 use

</mandatory_patterns>

### What is banned in M0 UI

<banned_practices type="m0_ui">

- Markdown rendering (bold, italics, headers, code blocks)
- File tree sidebar or navigation panel
- Settings page, preferences, or theme toggle
- Toolbar, formatting controls, or command palette
- Any animations, transitions, or visual feedback beyond the status bar
- Component libraries (shadcn/ui, Radix, etc.) — install post-M0 only
- Custom fonts or icon sets

</banned_practices>

---

## Design Philosophy (Post-Milestone 0 Vision)

<context type="design_philosophy">

Mada's visual language is built on three principles:

### 1. Performance as Aesthetic

The UI must feel instantaneous. Visual design decisions that introduce render cost (heavy shadows,
blur effects, large images, complex animations) are explicitly rejected unless they can be proven
not to degrade the <16ms keystroke latency target.

### 2. Cognitive Clarity

The editor surface is sacred. UI chrome should recede completely during writing sessions.
Inspired by: iA Writer's focus mode, Obsidian's minimal theme, Linear's information density.

### 3. Agent-Readable Tokens

All design decisions are expressed as structured tokens in this file's YAML frontmatter.
This allows Windsurf / Claude Code agents to reference exact values without hallucinating
colors or sizes. No "make it look good" prompts — every value is explicit.

</context>

---

## Design Tokens (Post-M0 Placeholders)

The following tokens are **NOT finalized**. They are structural placeholders to establish
the schema. Final values will be set after Milestone 0 validation during the Design Sprint.

### Color Palette

```yaml
# PLACEHOLDER — values not finalized
color:
  background:
    primary: "TBD"       # Main editor background
    secondary: "TBD"     # Sidebar, panels
    overlay: "TBD"       # Modals, popovers
  text:
    primary: "TBD"       # Body text
    secondary: "TBD"     # Muted labels, metadata
    accent: "TBD"        # Links, active states, highlights
  border:
    default: "TBD"
    subtle: "TBD"
  syntax:
    heading: "TBD"
    code: "TBD"
    link: "TBD"
    tag: "TBD"
```

### Typography

```yaml
# PLACEHOLDER — values not finalized
typography:
  font_family:
    editor: "TBD"        # Monospace or variable — decision deferred
    ui: "TBD"            # System UI stack preferred for performance
    code: "TBD"          # Monospace for inline code blocks
  font_size:
    base: "TBD"          # Body / editor default (rem)
    sm: "TBD"
    lg: "TBD"
    xl: "TBD"
  line_height:
    editor: "TBD"        # Optimized for long-form reading
    ui: "TBD"
  font_weight:
    normal: 400
    medium: 500
    bold: 700
```

### Spacing & Layout

```yaml
# PLACEHOLDER — values not finalized
spacing:
  unit: "TBD"            # Base spacing unit (rem or px)
  editor_max_width: "TBD"  # Max content width for readability
  sidebar_width: "TBD"
layout:
  border_radius:
    sm: "TBD"
    md: "TBD"
    lg: "TBD"
  shadow:
    sm: "TBD"
    md: "TBD"
```

### Motion

```yaml
# PLACEHOLDER — values not finalized
# All transitions must be validated against the <16ms keystroke latency target
motion:
  duration:
    instant: "0ms"       # State changes with no perceptible delay
    fast: "TBD"          # Micro-interactions (button press, toggle)
    moderate: "TBD"      # Panel open/close, modal enter
  easing:
    default: "TBD"
    spring: "TBD"
```

---

## Post-Milestone 0 Design Roadmap

Once all 10 Milestone 0 exit criteria are green:

1. **Design Sprint** — Finalize color palette (dark + light modes), typography selection, spacing scale
2. **Token Freeze** — Replace all `TBD` values above; commit as `feat: finalize design tokens`
3. **Component Library** — Implement shadcn/ui base components styled against finalized tokens
4. **Editor Theming** — Apply CodeMirror/ProseMirror theme using token values
5. **DESIGN.md Status Update** — Change `status: placeholder` → `status: active`

---

## Agent Instructions

<rules type="agent_behavior">

When this file's `status` is `placeholder`:
- Do **not** apply any visual styling beyond the M0 UI contract
- Do **not** install or configure component libraries
- Do **not** reference color or typography values — they are not finalized

When this file's `status` is `active`:
- All token values in the YAML frontmatter are the **single source of truth**
- Any color, size, or spacing not in this file requires human approval before use
- Deviations from these tokens must be flagged by the Critic-in-the-Loop hook

</rules>

---

**Authority:** This document is a placeholder until Milestone 0 completion. Post-M0, it becomes canonical for all visual design decisions. Revisions require human approval and a `docs(registry):` commit.
