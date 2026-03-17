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
  REPO=$(echo "$ISSUE_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/issues/[0-9]+.*|\1|')
  ISSUE_NUM=$(echo "$ISSUE_URL" | sed -E 's|.*/issues/([0-9]+).*|\1|')

  echo "=== Issue 元数据 ==="
  gh issue view "$ISSUE_NUM" --repo "$REPO" \
    --json title,body,author,labels,state,comments,createdAt,updatedAt 2>/dev/null || \
    gh issue view "$ISSUE_URL" \
    --json title,body,author,labels,state,comments,createdAt,updatedAt

  echo ""
  echo "=== Issue 评论 ==="
  gh issue view "$ISSUE_NUM" --repo "$REPO" --comments 2>/dev/null || \
    gh issue view "$ISSUE_URL" --comments

# GitLab
elif echo "$ISSUE_URL" | grep -q "gitlab.com"; then
  ISSUE_NUM=$(echo "$ISSUE_URL" | sed -E 's|.*issues/([0-9]+).*|\1|')

  echo "=== Issue 元数据 ==="
  glab issue view "$ISSUE_NUM" 2>/dev/null || echo "请确保已安装 glab CLI 并已登录：https://gitlab.com/gitlab-org/cli"

  echo ""
  echo "=== Issue 评论 ==="
  glab issue view "$ISSUE_NUM" --comments 2>/dev/null || echo "无法自动获取评论，请手动查看"

else
  echo "不支持的平台，请直接粘贴 issue 内容"
  exit 1
fi
