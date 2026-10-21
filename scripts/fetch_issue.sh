#!/usr/bin/env bash
# Fetch issue metadata and comments without requiring a local checkout.

set -euo pipefail

ISSUE_URL=${1:-}
if [[ -z "$ISSUE_URL" ]]; then
  echo "Usage: bash fetch_issue.sh <ISSUE_URL>" >&2
  exit 1
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "错误：未找到 $1 CLI。" >&2
    exit 1
  fi
}

if [[ "$ISSUE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)([/?#].*)?$ ]]; then
  require_command gh
  repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  number=${BASH_REMATCH[3]}

  if ! gh auth status >/dev/null 2>&1; then
    echo "错误：gh CLI 未认证。请先运行：gh auth login" >&2
    exit 1
  fi

  echo "=== Issue 元数据 ==="
  if ! gh issue view "$number" --repo "$repo" \
    --json title,body,author,labels,state,comments,createdAt,updatedAt,url; then
    echo "错误：无法获取 Issue #${number}（仓库：${repo}）。" >&2
    exit 1
  fi

  echo
  echo "=== Issue 评论 ==="
  if ! gh issue view "$number" --repo "$repo" --comments; then
    echo "警告：无法获取评论，后续分析需标注该上下文缺口。" >&2
  fi

elif [[ "$ISSUE_URL" =~ ^https://gitlab\.com/(.+)/-/issues/([0-9]+)([/?#].*)?$ ]]; then
  require_command glab
  repo=${BASH_REMATCH[1]}
  number=${BASH_REMATCH[2]}

  echo "=== Issue 元数据 ==="
  if ! glab issue view "$number" --repo "$repo"; then
    echo "错误：无法获取 Issue #${number}（仓库：${repo}）。" >&2
    exit 1
  fi

  echo
  echo "=== Issue 评论 ==="
  if ! glab issue view "$number" --repo "$repo" --comments; then
    echo "警告：无法获取评论，后续分析需标注该上下文缺口。" >&2
  fi

else
  echo "错误：不支持或无效的 Issue URL。仅支持 GitHub 和 GitLab Issue。" >&2
  exit 1
fi
