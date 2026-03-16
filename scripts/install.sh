#!/bin/bash
# install.sh - One-command installer for code-review-skill Claude Code skill
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/install.sh)

set -e

SKILL_NAME="code-review-skill"
REPO="googs1025/code-review-skill"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

echo "📦 Installing ${SKILL_NAME} Claude Code skill..."

# Check for git
if ! command -v git &>/dev/null; then
  echo "❌ git is required. Please install git first."
  exit 1
fi

# Check for gh CLI (optional but recommended)
if ! command -v gh &>/dev/null; then
  echo "⚠️  gh CLI not found. GitHub PR reviews will not work."
  echo "   Install from: https://cli.github.com"
fi

# Remove existing installation
if [ -d "$INSTALL_DIR" ]; then
  echo "🔄 Updating existing installation at ${INSTALL_DIR}..."
  rm -rf "$INSTALL_DIR"
fi

# Clone the repo
mkdir -p "$(dirname "$INSTALL_DIR")"
git clone --depth=1 "https://github.com/${REPO}.git" "$INSTALL_DIR"

# Make scripts executable
chmod +x "$INSTALL_DIR"/scripts/*.sh

echo ""
echo "✅ Installed successfully to ${INSTALL_DIR}"
echo ""
echo "🚀 Usage in Claude Code:"
echo "   /code-review-skill https://github.com/owner/repo/pull/123"
echo "   /code-review-skill  (then paste a diff or code snippet)"
echo ""
echo "📋 Prerequisites:"
echo "   - gh CLI (GitHub): https://cli.github.com"
echo "   - glab CLI (GitLab): https://gitlab.com/gitlab-org/cli"
