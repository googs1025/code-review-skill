#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file=$1
  local expected=$2
  grep -F -- "$expected" "$file" >/dev/null || fail "expected '$expected' in ${file#"$ROOT_DIR"/}"
}

assert_contains "$ROOT_DIR/SKILL.md" "## 合理性门槛"
assert_contains "$ROOT_DIR/SKILL.md" "实现正确不等于值得合并"
assert_contains "$ROOT_DIR/references/code_review.md" "## 合理性评估"
assert_contains "$ROOT_DIR/references/code_review.md" "- **需求合理性**："
assert_contains "$ROOT_DIR/references/code_review.md" "- **方案合理性**："
assert_contains "$ROOT_DIR/references/code_review.md" "合理 / 部分合理 / 不合理 / 证据不足"
assert_contains "$ROOT_DIR/references/issue_analysis.md" "- 合理性结论："
assert_contains "$ROOT_DIR/references/issue_analysis.md" "- 建议动作："
assert_contains "$ROOT_DIR/references/issue_analysis.md" "接受处理 / 缩小或改写 / 补充证据 / 延期 / 拒绝或关闭 / 无需处理"

echo "PASS: skill reasonableness contract"
