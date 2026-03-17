#!/bin/bash
# fetch_pr.sh - Fetch PR/MR metadata and diff from GitHub or GitLab
# Usage: bash fetch_pr.sh <PR_URL>

PR_URL="$1"

if [ -z "$PR_URL" ]; then
  echo "Usage: bash fetch_pr.sh <PR_URL>"
  exit 1
fi

# GitHub
if echo "$PR_URL" | grep -q "github.com"; then
  # Validate URL format
  if ! echo "$PR_URL" | grep -qE 'github\.com/.+/.+/pull/[0-9]+'; then
    echo "错误：无效的 GitHub PR URL 格式。期望格式：https://github.com/owner/repo/pull/123"
    exit 1
  fi

  # Check gh CLI is installed
  if ! command -v gh &>/dev/null; then
    echo "错误：未找到 gh CLI。请先安装：https://cli.github.com"
    exit 1
  fi

  # Check gh auth status
  if ! gh auth status &>/dev/null; then
    echo "错误：gh CLI 未认证。请先运行：gh auth login"
    exit 1
  fi

  REPO=$(echo "$PR_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/[0-9]+.*|\1|')
  PR_NUM=$(echo "$PR_URL" | sed -E 's|.*/pull/([0-9]+).*|\1|')

  echo "=== PR 元数据 ==="
  if ! gh pr view "$PR_NUM" --repo "$REPO" \
    --json title,body,author,labels,files,additions,deletions,baseRefName,headRefName 2>&1; then
    echo "错误：无法获取 PR #${PR_NUM}（仓库：${REPO}）。请检查 PR 是否存在以及是否有访问权限。"
    exit 1
  fi

  echo ""
  echo "=== PR Diff 统计 ==="
  DIFF_STAT=$(gh pr diff "$PR_NUM" --repo "$REPO" 2>&1 | diffstat -s 2>/dev/null || true)
  FILE_COUNT=$(gh pr view "$PR_NUM" --repo "$REPO" --json files --jq '.files | length' 2>/dev/null || echo "0")
  ADD_COUNT=$(gh pr view "$PR_NUM" --repo "$REPO" --json additions --jq '.additions' 2>/dev/null || echo "0")
  DEL_COUNT=$(gh pr view "$PR_NUM" --repo "$REPO" --json deletions --jq '.deletions' 2>/dev/null || echo "0")
  TOTAL_LINES=$((ADD_COUNT + DEL_COUNT))

  echo "文件数: ${FILE_COUNT}, 新增行: ${ADD_COUNT}, 删除行: ${DEL_COUNT}, 总变更行: ${TOTAL_LINES}"

  if [ "$FILE_COUNT" -gt 100 ] || [ "$TOTAL_LINES" -gt 3000 ] 2>/dev/null; then
    echo ""
    echo "⚠️  大 PR 警告：${FILE_COUNT} 个文件, ${TOTAL_LINES} 行变更"
    echo "自动过滤以下文件的 diff：lock 文件、vendor 目录、生成代码"
    echo ""
    echo "=== PR Diff（已过滤机器生成文件） ==="
    if ! gh pr diff "$PR_NUM" --repo "$REPO" 2>&1 | \
      awk '
        /^diff --git/ {
          skip = 0
          if ($0 ~ /\/(vendor|node_modules|third_party|generated|__generated__)\//) skip = 1
          if ($0 ~ /\.(lock|sum|min\.js|min\.css|pb\.go|generated\.go|snap)[ \t]/) skip = 1
          if ($0 ~ /package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|Pipfile\.lock|composer\.lock|Gemfile\.lock|poetry\.lock/) skip = 1
        }
        !skip { print }
      '; then
      echo "错误：无法获取 PR diff。请检查 PR 是否存在以及是否有访问权限。"
      exit 1
    fi
  else
    echo ""
    echo "=== PR Diff ==="
    if ! gh pr diff "$PR_NUM" --repo "$REPO" 2>&1; then
      echo "错误：无法获取 PR diff。请检查 PR 是否存在以及是否有访问权限。"
      exit 1
    fi
  fi

# GitLab
elif echo "$PR_URL" | grep -q "gitlab.com"; then
  # Check glab CLI is installed
  if ! command -v glab &>/dev/null; then
    echo "错误：未找到 glab CLI。请先安装：https://gitlab.com/gitlab-org/cli"
    exit 1
  fi

  MR_NUM=$(echo "$PR_URL" | sed -E 's|.*merge_requests/([0-9]+).*|\1|')

  echo "=== MR 元数据 ==="
  if ! glab mr view "$MR_NUM" 2>&1; then
    echo "错误：无法获取 MR #${MR_NUM}。请确保已登录 glab（glab auth login）并检查 MR 是否存在。"
    exit 1
  fi

  echo ""
  echo "=== MR Diff ==="
  MR_DIFF=$(glab mr diff "$MR_NUM" 2>&1) || { echo "警告：无法自动获取 diff，请手动粘贴"; MR_DIFF=""; }
  if [ -n "$MR_DIFF" ]; then
    MR_DIFF_LINES=$(echo "$MR_DIFF" | wc -l)
    MR_FILE_COUNT=$(echo "$MR_DIFF" | grep -c '^diff --git' || true)
    echo "文件数: ${MR_FILE_COUNT}, diff 行数: ${MR_DIFF_LINES}"
    if [ "$MR_FILE_COUNT" -gt 100 ] || [ "$MR_DIFF_LINES" -gt 6000 ] 2>/dev/null; then
      echo ""
      echo "⚠️  大 MR 警告：${MR_FILE_COUNT} 个文件, ${MR_DIFF_LINES} 行 diff"
      echo "自动过滤 lock 文件、vendor 目录、生成代码的 diff"
      echo "$MR_DIFF" | awk '
        /^diff --git/ {
          skip = 0
          if ($0 ~ /\/(vendor|node_modules|third_party|generated|__generated__)\//) skip = 1
          if ($0 ~ /\.(lock|sum|min\.js|min\.css|pb\.go|generated\.go|snap)[ \t]/) skip = 1
          if ($0 ~ /package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|Pipfile\.lock|composer\.lock|Gemfile\.lock|poetry\.lock/) skip = 1
        }
        !skip { print }
      '
    else
      echo "$MR_DIFF"
    fi
  fi

else
  echo "不支持的平台，请直接粘贴 diff 内容"
  exit 1
fi
