#!/usr/bin/env bash
# Fetch PR/MR metadata and diff without requiring a local checkout.

set -euo pipefail

PR_URL=${1:-}
if [[ -z "$PR_URL" ]]; then
  echo "Usage: bash fetch_pr.sh <PR_OR_MR_URL>" >&2
  exit 1
fi

DIFF_FILE=$(mktemp "${TMPDIR:-/tmp}/code-review-diff.XXXXXX")
trap 'rm -f "$DIFF_FILE"' EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "错误：未找到 $1 CLI。" >&2
    exit 1
  fi
}

print_github_review_context() {
  local repo=$1
  local number=$2

  echo
  echo "=== Existing Review Context ==="
  echo "以下内容可能来自 AI、机器人或人工 reviewer；需结合当前 PR head 独立验证，不可直接采信。"

  echo
  echo "--- Review summaries ---"
  if ! gh api --paginate "repos/${repo}/pulls/${number}/reviews" --jq \
    '.[] | {kind:"review", id, author:.user.login, author_type:.user.type, state, body, commit_id, submitted_at, url:.html_url}'; then
    echo "警告：无法获取 review summaries。" >&2
  fi

  echo
  echo "--- Inline review comments and replies ---"
  if ! gh api --paginate "repos/${repo}/pulls/${number}/comments" --jq \
    '.[] | {kind:"inline_comment", id, reply_to:.in_reply_to_id, author:.user.login, author_type:.user.type, body, path, line:(.line // .original_line), side:(.side // .original_side), commit_id, original_commit_id, created_at, updated_at, url:.html_url, diff_hunk}'; then
    echo "警告：无法获取 inline review comments。" >&2
  fi

  echo
  echo "--- General PR comments ---"
  if ! gh api --paginate "repos/${repo}/issues/${number}/comments" --jq \
    '.[] | {kind:"pr_comment", id, author:.user.login, author_type:.user.type, author_association, body, created_at, updated_at, url:.html_url}'; then
    echo "警告：无法获取 PR comments。" >&2
  fi
}

print_diff() {
  local kind=$1
  local file_count additions deletions total_lines
  file_count=$(awk '/^diff --git / { count++ } END { print count + 0 }' "$DIFF_FILE")
  additions=$(awk '/^\+[^+]/ { count++ } END { print count + 0 }' "$DIFF_FILE")
  deletions=$(awk '/^-[^-]/ { count++ } END { print count + 0 }' "$DIFF_FILE")
  total_lines=$((additions + deletions))

  echo
  echo "=== ${kind} Diff 统计 ==="
  echo "文件数: ${file_count}, 新增行: ${additions}, 删除行: ${deletions}, 总变更行: ${total_lines}"

  if ((file_count > 100 || total_lines > 3000)); then
    echo
    echo "⚠️  大型变更：输出已跳过常见依赖、vendor 和生成文件；元数据仍保留完整文件列表。"
    echo "=== ${kind} Diff（已过滤低信号文件） ==="
    awk '
      /^diff --git/ {
        skip = 0
        if ($0 ~ /\/(vendor|node_modules|third_party|generated|__generated__)\//) skip = 1
        if ($0 ~ /package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|Pipfile\.lock|composer\.lock|Gemfile\.lock|poetry\.lock/) skip = 1
        if ($0 ~ /\.(min\.js|min\.css|pb\.go|generated\.go|snap)( |$)/) skip = 1
      }
      !skip { print }
    ' "$DIFF_FILE"
  else
    echo
    echo "=== ${kind} Diff ==="
    cat "$DIFF_FILE"
  fi
}

if [[ "$PR_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)([/?#].*)?$ ]]; then
  require_command gh
  repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  number=${BASH_REMATCH[3]}

  if ! gh auth status >/dev/null 2>&1; then
    echo "错误：gh CLI 未认证。请先运行：gh auth login" >&2
    exit 1
  fi

  echo "=== PR 元数据 ==="
  if ! gh pr view "$number" --repo "$repo" \
    --json title,body,author,labels,files,additions,deletions,baseRefName,headRefName,headRefOid,state,url; then
    echo "错误：无法获取 PR #${number}（仓库：${repo}）。" >&2
    exit 1
  fi

  print_github_review_context "$repo" "$number"

  if ! gh pr diff "$number" --repo "$repo" >"$DIFF_FILE" 2>&1; then
    echo "错误：无法获取 PR diff（仓库：${repo}，PR：#${number}）。" >&2
    sed -n '1,20p' "$DIFF_FILE" >&2
    exit 1
  fi
  print_diff "PR"

elif [[ "$PR_URL" =~ ^https://gitlab\.com/(.+)/-/merge_requests/([0-9]+)([/?#].*)?$ ]]; then
  require_command glab
  repo=${BASH_REMATCH[1]}
  number=${BASH_REMATCH[2]}

  echo "=== MR 元数据 ==="
  if ! glab mr view "$number" --repo "$repo"; then
    echo "错误：无法获取 MR !${number}（仓库：${repo}）。" >&2
    exit 1
  fi

  if ! glab mr diff "$number" --repo "$repo" --raw >"$DIFF_FILE" 2>&1; then
    echo "错误：无法获取 MR diff（仓库：${repo}，MR：!${number}）。" >&2
    sed -n '1,20p' "$DIFF_FILE" >&2
    exit 1
  fi
  print_diff "MR"

else
  echo "错误：不支持或无效的 PR/MR URL。仅支持 github.com/.../pull/<n> 和 gitlab.com/.../-/merge_requests/<n>。" >&2
  exit 1
fi
