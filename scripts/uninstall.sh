#!/bin/bash
# uninstall.sh - Uninstaller for code-review-skill Claude Code skill
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/uninstall.sh)

set -e

SKILL_NAME="code-review-skill"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

echo "🗑  Uninstalling ${SKILL_NAME} Claude Code skill..."

if [ ! -d "$INSTALL_DIR" ]; then
  echo "⚠️  ${SKILL_NAME} is not installed at ${INSTALL_DIR}. Nothing to do."
  exit 0
fi

# Confirm before removing
echo "   Will remove: ${INSTALL_DIR}"
read -p "   Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "❌ Uninstall cancelled."
  exit 0
fi

rm -rf "$INSTALL_DIR"

echo ""
echo "✅ ${SKILL_NAME} has been uninstalled successfully."
echo "   Other skills in ~/.claude/skills/ are untouched."
