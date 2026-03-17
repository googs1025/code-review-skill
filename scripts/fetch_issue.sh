#!/bin/bash
# fetch_issue.sh - Fetch issue metadata and comments from GitHub or GitLab
# Usage: bash fetch_issue.sh <ISSUE_URL>

ISSUE_URL="$1"

if [ -z "$ISSUE_URL" ]; then
  echo "Usage: bash fetch_issue.sh <ISSUE_URL>"
  exit 1
fi

# GitHub
if echo "$ISSUE_URL" | grep -q "github.com"; then
  # Validate URL format
  if ! echo "$ISSUE_URL" | grep -qE 'github\.com/.+/.+/issues/[0-9]+'; then
    echo "错误：无效的 GitHub Issue URL 格式。期望格式：https://github.com/owner/repo/issues/123"
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

  REPO=$(echo "$ISSUE_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/issues/[0-9]+.*|\1|')
  ISSUE_NUM=$(echo "$ISSUE_URL" | sed -E 's|.*/issues/([0-9]+).*|\1|')

  echo "=== Issue 元数据 ==="
  if ! gh issue view "$ISSUE_NUM" --repo "$REPO" \
    --json title,body,author,labels,state,comments,createdAt,updatedAt 2>&1; then
    echo "错误：无法获取 Issue #${ISSUE_NUM}（仓库：${REPO}）。请检查 Issue 是否存在以及是否有访问权限。"
    exit 1
  fi

  echo ""
  echo "=== Issue 评论 ==="
  gh issue view "$ISSUE_NUM" --repo "$REPO" --comments 2>&1 || \
    echo "警告：无法获取评论，请手动查看。"

# GitLab
elif echo "$ISSUE_URL" | grep -q "gitlab.com"; then
  # Check glab CLI is installed
  if ! command -v glab &>/dev/null; then
    echo "错误：未找到 glab CLI。请先安装：https://gitlab.com/gitlab-org/cli"
    exit 1
  fi

  ISSUE_NUM=$(echo "$ISSUE_URL" | sed -E 's|.*issues/([0-9]+).*|\1|')

  echo "=== Issue 元数据 ==="
  if ! glab issue view "$ISSUE_NUM" 2>&1; then
    echo "错误：无法获取 Issue #${ISSUE_NUM}。请确保已登录 glab（glab auth login）并检查 Issue 是否存在。"
    exit 1
  fi

  echo ""
  echo "=== Issue 评论 ==="
  glab issue view "$ISSUE_NUM" --comments 2>&1 || echo "警告：无法自动获取评论，请手动查看"

else
  echo "不支持的平台，请直接粘贴 issue 内容"
  exit 1
fi
