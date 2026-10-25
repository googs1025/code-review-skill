#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

BIN_DIR="$TEST_TMP/bin"
mkdir -p "$BIN_DIR"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file=$1
  local expected=$2
  grep -F -- "$expected" "$file" >/dev/null || fail "expected '$expected' in $file"
}

test_gitlab_pr_uses_repo_from_url() {
  local log="$TEST_TMP/glab-pr.log"
  local output="$TEST_TMP/glab-pr.out"

  cat >"$BIN_DIR/glab" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
if [[ "$*" == "mr diff"* ]]; then
  cat <<'DIFF'
diff --git a/a.go b/a.go
--- a/a.go
+++ b/a.go
-old
+new
DIFF
else
  echo '{"title":"example"}'
fi
EOF
  chmod +x "$BIN_DIR/glab"

  CALL_LOG="$log" PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_pr.sh" \
    "https://gitlab.com/acme/platform/service/-/merge_requests/456" >"$output"

  assert_contains "$log" "mr view 456 --repo acme/platform/service"
  assert_contains "$log" "mr diff 456 --repo acme/platform/service --raw"
}

test_gitlab_issue_uses_repo_from_url() {
  local log="$TEST_TMP/glab-issue.log"
  local output="$TEST_TMP/glab-issue.out"

  cat >"$BIN_DIR/glab" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
echo 'issue data'
EOF
  chmod +x "$BIN_DIR/glab"

  CALL_LOG="$log" PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_issue.sh" \
    "https://gitlab.com/acme/platform/service/-/issues/42" >"$output"

  assert_contains "$log" "issue view 42 --repo acme/platform/service"
  assert_contains "$log" "issue view 42 --repo acme/platform/service --comments"
}

test_github_diff_failure_is_not_hidden() {
  local output="$TEST_TMP/gh-failure.out"

  cat >"$BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "auth status" ]]; then
  exit 0
fi
if [[ "$*" == "pr view"* ]]; then
  echo '{"title":"example","files":[]}'
  exit 0
fi
if [[ "$*" == "api"* ]]; then
  exit 0
fi
if [[ "$*" == "pr diff"* ]]; then
  echo 'simulated diff failure' >&2
  exit 17
fi
exit 1
EOF
  chmod +x "$BIN_DIR/gh"

  if PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_pr.sh" \
    "https://github.com/acme/service/pull/7" >"$output" 2>&1; then
    fail "fetch_pr.sh succeeded after gh pr diff failed"
  fi
  assert_contains "$output" "无法获取 PR diff"
}

test_github_diff_is_fetched_once() {
  local log="$TEST_TMP/gh-once.log"
  local output="$TEST_TMP/gh-once.out"

  cat >"$BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
if [[ "$*" == "auth status" ]]; then
  exit 0
fi
if [[ "$*" == "pr view"* ]]; then
  echo '{"title":"example","files":[{"path":"a.go"}]}'
  exit 0
fi
if [[ "$*" == "api"* ]]; then
  exit 0
fi
if [[ "$*" == "pr diff"* ]]; then
  cat <<'DIFF'
diff --git a/a.go b/a.go
--- a/a.go
+++ b/a.go
-old
+new
DIFF
  exit 0
fi
exit 1
EOF
  chmod +x "$BIN_DIR/gh"

  CALL_LOG="$log" PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_pr.sh" \
    "https://github.com/acme/service/pull/7" >"$output"

  [[ $(grep -c '^pr diff ' "$log") -eq 1 ]] || fail "expected exactly one gh pr diff call"
}

test_github_fetches_existing_review_context() {
  local log="$TEST_TMP/gh-review-context.log"
  local output="$TEST_TMP/gh-review-context.out"

  cat >"$BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
if [[ "$*" == "auth status" ]]; then
  exit 0
fi
if [[ "$*" == "pr view"* ]]; then
  echo '{"title":"example","headRefOid":"abc123"}'
  exit 0
fi
if [[ "$*" == "pr diff"* ]]; then
  cat <<'DIFF'
diff --git a/a.go b/a.go
--- a/a.go
+++ b/a.go
-old
+new
DIFF
  exit 0
fi
if [[ "$*" == "api"* ]]; then
  echo '{"kind":"review-context"}'
  exit 0
fi
exit 1
EOF
  chmod +x "$BIN_DIR/gh"

  CALL_LOG="$log" PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_pr.sh" \
    "https://github.com/acme/service/pull/7" >"$output"

  assert_contains "$log" "api --paginate repos/acme/service/pulls/7/reviews"
  assert_contains "$log" "api --paginate repos/acme/service/pulls/7/comments"
  assert_contains "$log" "api --paginate repos/acme/service/issues/7/comments"
  assert_contains "$output" "=== Existing Review Context ==="
}

test_deceptive_github_url_is_rejected() {
  local output="$TEST_TMP/deceptive-url.out"

  if PATH="$BIN_DIR:$PATH" bash "$ROOT_DIR/scripts/fetch_pr.sh" \
    "https://evil.test/github.com/acme/service/pull/7" >"$output" 2>&1; then
    fail "accepted a URL whose host is not github.com"
  fi
  assert_contains "$output" "不支持或无效的 PR/MR URL"
}

test_single_commit_fetch_does_not_include_ancestors() {
  local repo="$TEST_TMP/commit-repo"
  local output="$TEST_TMP/single-commit.out"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config commit.gpgsign false

  printf 'first-only\n' >"$repo/history.txt"
  git -C "$repo" add history.txt
  git -C "$repo" commit -q -m first
  printf 'second-only\n' >>"$repo/history.txt"
  git -C "$repo" commit -qam second
  local second_commit
  second_commit=$(git -C "$repo" rev-parse HEAD)
  printf 'third-only\n' >>"$repo/history.txt"
  git -C "$repo" commit -qam third

  (cd "$repo" && bash "$ROOT_DIR/scripts/fetch_commits.sh" "$second_commit") >"$output"

  [[ $(grep -c '^commit ' "$output") -eq 1 ]] || fail "single-commit output included ancestor commits"
  assert_contains "$output" "second-only"
}

test_review_depth_contracts() {
  assert_contains "$ROOT_DIR/SKILL.md" "读取线上材料后"
  assert_contains "$ROOT_DIR/SKILL.md" "两个独立选择"
  assert_contains "$ROOT_DIR/SKILL.md" "明确要求不要提问或不要中断"
  assert_contains "$ROOT_DIR/SKILL.md" "未选择的选项按“否”处理"
  assert_contains "$ROOT_DIR/references/code_review.md" "轻量审查不得拉取或检出仓库，也不得运行本地测试"
  assert_contains "$ROOT_DIR/references/code_review.md" "最小相关测试"
  assert_contains "$ROOT_DIR/references/code_review.md" "安装依赖、启动容器、访问外部服务"
  assert_contains "$ROOT_DIR/references/code_review.md" "核心执行流程、数据与状态流转、模块边界、接口契约、错误路径、兼容性和设计取舍"
}

test_subagent_issue_contracts() {
  assert_contains "$ROOT_DIR/references/code_review.md" "只启用一个子 agent"
  assert_contains "$ROOT_DIR/references/code_review.md" "与是否进行本地验证分开决定"
  assert_contains "$ROOT_DIR/references/code_review.md" "子 agent 的结论只作为候选线索"
  assert_contains "$ROOT_DIR/references/code_review.md" "主 agent 必须对照当前代码独立验证"
  assert_contains "$ROOT_DIR/references/issue_analysis.md" "读取线上材料后"
  assert_contains "$ROOT_DIR/references/issue_analysis.md" "两个独立选择"
  assert_contains "$ROOT_DIR/references/issue_analysis.md" "轻量分析不得拉取或检出仓库，也不得运行本地测试"
}

test_single_commit_fetch_does_not_include_ancestors
test_gitlab_pr_uses_repo_from_url
test_gitlab_issue_uses_repo_from_url
test_github_diff_failure_is_not_hidden
test_github_diff_is_fetched_once
test_github_fetches_existing_review_context
test_deceptive_github_url_is_rejected
test_review_depth_contracts
test_subagent_issue_contracts

echo "PASS: 9 script behavior tests"
