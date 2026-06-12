#!/usr/bin/env bash
# Installs the ttt CLI, the Claude Code skill, and the Codex prompt.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${TTT_BIN_DIR:-$HOME/.local/bin}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required (3.9+)" >&2
  exit 1
fi

# 1. CLI
mkdir -p "$BIN_DIR"
ln -sf "$REPO_DIR/bin/ttt" "$BIN_DIR/ttt"
echo "Installed CLI: $BIN_DIR/ttt"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "  note: add $BIN_DIR to your PATH" ;;
esac

# 2. Claude Code skill (works without the plugin marketplace)
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
rm -rf "$CLAUDE_SKILLS_DIR/tabtabtab"
cp -R "$REPO_DIR/skills/tabtabtab" "$CLAUDE_SKILLS_DIR/tabtabtab"
echo "Installed Claude Code skill: $CLAUDE_SKILLS_DIR/tabtabtab"
echo "  (or install as a plugin: /plugin marketplace add tabtabtabai/ttt-skill)"

# 3. Codex prompt
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"
mkdir -p "$CODEX_PROMPTS_DIR"
cp "$REPO_DIR/codex/ttt.md" "$CODEX_PROMPTS_DIR/ttt.md"
echo "Installed Codex prompt: $CODEX_PROMPTS_DIR/ttt.md (use /ttt in Codex)"

echo
echo "Next: run 'ttt login' to authenticate, then 'ttt vm list'."
