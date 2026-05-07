#!/usr/bin/env bash
# Mada Test Vault Setup Script
# Creates a local test vault fixture for Milestone 0 development and testing

set -euo pipefail

VAULT_ROOT="$HOME/Mada_Test_Vault"
NOTES_DIR="$VAULT_ROOT/01_Notes"

echo "=== Mada Test Vault Setup ==="
echo "Creating test vault at: $VAULT_ROOT"

# Create directory structure
mkdir -p "$NOTES_DIR"

# Seed index.md in vault root
cat > "$VAULT_ROOT/index.md" << 'EOF'
# Mada Test Vault

Welcome to the Mada test vault. This is a sandbox environment for Milestone 0 development and validation.

## Purpose

This vault serves as the hardcoded test fixture for validating:
- Tauri IPC file operations (read/write with <50ms latency)
- Concurrent edit convergence (Loro CRDT)
- File watcher responsiveness (external editor detection)
- SQLite index layer performance

## Test Scenarios

1. **Single-file editing:** Type in the Mada UI while this file is open
2. **External edit detection:** Modify this file in VS Code/Vim while Mada is running
3. **Concurrent convergence:** Run `scripts/concurrent_edit_test.sh` while typing in Mada
4. **Cross-file references:** Link to [[Test Note]] to validate fuzzy anchoring

## Sample List

- First item with some content
- Second item with **bold text** and *italics*
- Third item with a `code snippet`
  - Nested item to test outliner parsing
  - Another nested item with more text to exercise the Tree-sitter parser

## Wikilink Test

This vault contains a reference to [[Test Note]] in the `01_Notes/` directory.

---

**Last Updated:** 2026-05-07  
**Vault Version:** v0.0.0.0.1  
**Purpose:** Milestone 0 Test Fixture
EOF

# Seed Test Note.md in 01_Notes/
cat > "$NOTES_DIR/Test Note.md" << 'EOF'
# Test Note

This is a test note located in the `01_Notes/` subdirectory.

## Purpose

This file validates:
- Folder traversal and file discovery
- Cross-file wikilink resolution
- Multi-file indexing in SQLite

## Content

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

### Subsection

More content to exercise the parser and ensure we have sufficient text for meaningful tests.

- List item one
- List item two
- List item three

Back to [[index]] to test bidirectional linking.
EOF

echo "✓ Created $VAULT_ROOT/index.md"
echo "✓ Created $NOTES_DIR/Test Note.md"
echo ""
echo "Test vault setup complete!"
echo "Vault location: $VAULT_ROOT"
echo ""
echo "Next steps:"
echo "  1. Verify files exist: ls -la $VAULT_ROOT"
echo "  2. Set environment: export MADA_VAULT_PATH=$VAULT_ROOT"
echo "  3. Run Mada: cargo tauri dev"
