#!/bin/bash
# fetch_commits.sh - Fetch commit history and diff details
# Usage: bash fetch_commits.sh [commit_range_or_hash]
# Examples:
#   bash fetch_commits.sh HEAD~5..HEAD
#   bash fetch_commits.sh abc1234

# Check if we're inside a git repository
if ! git rev-parse --git-dir &>/dev/null; then
  echo "错误：当前目录不是 git 仓库。请在 git 仓库内运行此脚本。"
  exit 1
fi

TARGET="${1:-HEAD~5..HEAD}"

# Validate the target argument
if ! git rev-parse "$TARGET" &>/dev/null 2>&1; then
  echo "错误：无效的 commit 引用 '${TARGET}'。请检查 commit hash 或范围是否正确。"
  exit 1
fi

echo "=== Commit 概览 ==="
git log --oneline "$TARGET" 2>&1 || git log --oneline -10

echo ""
echo "=== 详细变更 ==="
git log --stat --patch "$TARGET" 2>&1 || git show "$TARGET"
