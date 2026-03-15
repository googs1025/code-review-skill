#!/bin/bash
# fetch_commits.sh - Fetch commit history and diff details
# Usage: bash fetch_commits.sh [commit_range_or_hash]
# Examples:
#   bash fetch_commits.sh HEAD~5..HEAD
#   bash fetch_commits.sh abc1234

TARGET="${1:-HEAD~5..HEAD}"

echo "=== Commit 概览 ==="
git log --oneline "$TARGET" 2>/dev/null || git log --oneline -10

echo ""
echo "=== 详细变更 ==="
git log --stat --patch "$TARGET" 2>/dev/null || git show "$TARGET"
