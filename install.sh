#!/usr/bin/env bash
# Installs the official tabtabtab CLI, the Claude Code skill, and the Codex prompt.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. The tabtabtab CLI (PyPI package: tabtabtab)
if command -v tabtabtab >/dev/null 2>&1; then
  echo "tabtabtab CLI already installed: $(command -v tabtabtab)"
elif command -v uv >/dev/null 2>&1; then
  uv tool install tabtabtab
  echo "Installed tabtabtab CLI with uv."
elif command -v pipx >/dev/null 2>&1; then
  pipx install tabtabtab
  echo "Installed tabtabtab CLI with pipx."
elif command -v pip3 >/dev/null 2>&1; then
  pip3 install --user tabtabtab
  echo "Installed tabtabtab CLI with pip3 --user."
else
  echo "error: install the tabtabtab CLI first: curl -fsSL https://tabtabtab.ai/install.sh | sh" >&2
  exit 1
fi

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
echo "Next: run 'tabtabtab auth login', then 'tabtabtab env list'."
