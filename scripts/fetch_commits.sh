#!/usr/bin/env bash
# Fetch one commit or an explicit commit range from the current repository.

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "错误：当前目录不是 git 仓库。请在目标仓库内运行此脚本。" >&2
  exit 1
fi

target=${1:-HEAD~5..HEAD}

if [[ "$target" == *..* ]]; then
  if ! git rev-list "$target" >/dev/null 2>&1; then
    echo "错误：无效的 commit 范围 '${target}'。" >&2
    exit 1
  fi
  echo "=== Commit 概览 ==="
  git log --oneline "$target"
  echo
  echo "=== 详细变更 ==="
  git log --stat --patch "$target"
else
  if ! git rev-parse --verify "${target}^{commit}" >/dev/null 2>&1; then
    echo "错误：无效的 commit 引用 '${target}'。" >&2
    exit 1
  fi
  echo "=== Commit 概览 ==="
  git show --no-patch --oneline "$target"
  echo
  echo "=== 详细变更 ==="
  git show --stat --patch "$target"
fi
