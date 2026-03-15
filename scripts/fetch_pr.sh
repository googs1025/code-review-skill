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
  REPO=$(echo "$PR_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/[0-9]+.*|\1|')
  PR_NUM=$(echo "$PR_URL" | sed -E 's|.*/pull/([0-9]+).*|\1|')

  echo "=== PR 元数据 ==="
  gh pr view "$PR_NUM" --repo "$REPO" \
    --json title,body,author,labels,files,additions,deletions,baseRefName,headRefName 2>/dev/null || \
    gh pr view "$PR_URL" \
    --json title,body,author,labels,files,additions,deletions,baseRefName,headRefName

  echo ""
  echo "=== PR Diff ==="
  gh pr diff "$PR_NUM" --repo "$REPO" 2>/dev/null || gh pr diff "$PR_URL"

# GitLab
elif echo "$PR_URL" | grep -q "gitlab.com"; then
  MR_NUM=$(echo "$PR_URL" | sed -E 's|.*merge_requests/([0-9]+).*|\1|')

  echo "=== MR 元数据 ==="
  glab mr view "$MR_NUM" 2>/dev/null || echo "请确保已安装 glab CLI 并已登录：https://gitlab.com/gitlab-org/cli"

  echo ""
  echo "=== MR Diff ==="
  glab mr diff "$MR_NUM" 2>/dev/null || echo "无法自动获取 diff，请手动粘贴"

else
  echo "不支持的平台，请直接粘贴 diff 内容"
  exit 1
fi
