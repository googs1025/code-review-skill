# code-review-skill

An evidence-first code review skill for Codex and Claude Code. It supports GitHub/GitLab PR links, raw diffs, code snippets, commits, module reviews, and issue analysis while prioritizing actionable findings over checklist noise.

[中文文档](#中文文档)

---

## Features

- **Auto-detects input type** — PR URL, diff, code snippet, commit range, or issue link
- **Issue analysis** — paste a GitHub/GitLab issue URL, get problem analysis and solution ideas
- **Evidence-first findings** — requires a reachable path, concrete impact, and precise location
- **Calibrated grading** — separates Critical/Major/Minor impact from confidence
- **Complete PR reports** — overview, motivation, core changes, technical approach, severity sections, verification, and verdict
- **Adaptive focused output** — concise for snippets and explicitly scoped reviews
- **Existing-review assessment** — independently checks substantive AI/bot comments against the current PR head
- **Explicit review depth** — after reading an online Issue or PR, asks whether to keep the review lightweight or pull the code for local validation
- **Optional second perspective** — independently asks whether to use one subagent, then verifies its candidate findings before reporting them
- **Flow and design focus** — prioritizes execution paths, state transitions, module boundaries, contracts, error paths, compatibility, and design tradeoffs
- **GitHub & GitLab** — works with both platforms via `gh` and `glab` CLIs
- **Language-aware** — security checklist covers Go, Python, JS/TS, Rust, Java

## Installation

### Claude Code one-line install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/install.sh)
```

### Codex install

```bash
git clone https://github.com/googs1025/code-review-skill.git \
  ~/.codex/skills/code-review-skill
```

### Manual install

```bash
git clone https://github.com/googs1025/code-review-skill.git \
  ~/.claude/skills/code-review-skill
chmod +x ~/.claude/skills/code-review-skill/scripts/*.sh
```

### Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| Codex or [Claude Code](https://claude.ai/code) | ✅ Yes | Agent runtime |
| [gh CLI](https://cli.github.com) | For GitHub PRs and issues | Fetch PR/issue metadata and diff |
| [glab CLI](https://gitlab.com/gitlab-org/cli) | For GitLab MRs and issues | Fetch MR/issue metadata and diff |

**Platform compatibility**: macOS, Linux, WSL2. Native Windows (cmd/PowerShell) is not supported.

**Minimum versions**: gh >= 2.0, glab >= 1.22, git >= 2.20, bash >= 4.0.

Make sure you're authenticated:

```bash
gh auth login    # GitHub
glab auth login  # GitLab
```

## Usage

Codex can discover the skill automatically for review requests, or you can invoke `$code-review-skill` explicitly. In Claude Code, use `/code-review-skill`.

```
# Review a GitHub PR
/code-review-skill https://github.com/owner/repo/pull/123

# Review a GitLab MR
/code-review-skill https://gitlab.com/group/project/-/merge_requests/456

# Analyze a GitHub Issue
/code-review-skill https://github.com/owner/repo/issues/456

# Review a pasted diff or code snippet
/code-review-skill
```

For an online Issue or PR, the skill reads the available description, diff, comments, related context, and CI first. It then asks two independent questions: whether to pull or check out the code for local validation, and whether to use one subagent for an independent review.

- A lightweight review does not clone, fetch, check out, or run local tests.
- If local validation is approved, the skill runs the smallest relevant tests without asking about every command. Installing dependencies, starting containers, accessing external services, or otherwise expanding the local environment still requires separate approval.
- If a subagent is approved, it focuses on the main execution flow and design boundaries. Its output remains candidate evidence until the primary agent independently verifies it.

### Example output

```
## Review 概览
- **变更类型**: Bug 修复
- **风险等级**: 中
- **变更摘要**: 修正 PD 配置中的镜像版本不一致
- **受影响模块**: deployment examples

## PR 主要工作

### 背景与动机
避免 prefill/decode 运行不兼容的协议版本。

### 核心变更
将两端镜像固定到同一个已验证版本。

### 技术方案
保持现有部署结构，只统一镜像 tag。

## Critical Issues（必须解决才能合并）
✅ 无 Critical 问题

## Major Issues（强烈建议修复）

### [高置信度] PD YAML 中 prefill/decode 镜像版本不一致
- **位置**: `tensor-rt-pd.yaml:47` vs `:88`
- **证据**: prefill 固定 `:1.0.0`，decode 使用 `:latest`
- **影响**: 两端可能运行不兼容协议版本
- **建议**: 将两端固定到同一个已验证版本

## Minor Issues（可选优化）
✅ 无 Minor 问题

## Verification
- 配置渲染测试：通过

## 总体评价
**结论**: REQUEST_CHANGES
```

## Update

```bash
cd ~/.claude/skills/code-review-skill && git pull
```

Or re-run the one-line installer.

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/uninstall.sh)
```

Or manually:

```bash
rm -rf ~/.claude/skills/code-review-skill
```

This only removes the `code-review-skill` directory — other skills in `~/.claude/skills/` are not affected.

## File structure

```
code-review-skill/
├── SKILL.md                        # Skill prompt (loaded by Claude Code)
├── scripts/
│   ├── fetch_pr.sh                 # Fetch PR/MR metadata and diff
│   ├── fetch_issue.sh              # Fetch issue metadata and comments
│   ├── fetch_commits.sh            # Fetch commit history
│   ├── install.sh                  # One-command installer
│   └── uninstall.sh                # One-command uninstaller
├── references/
│   ├── code_review.md              # Detailed code review workflow
│   ├── issue_analysis.md           # Issue-specific analysis workflow
│   └── security_checklist.md       # Evidence-oriented security guide
└── tests/
    └── scripts_test.sh             # Fetch helper behavior tests
```

## How it works

1. The agent loads `SKILL.md` and routes the request by input type.
2. GitHub PR fetching also collects review summaries, inline threads, and general PR comments.
3. After online Issue/PR evidence is read, the user independently chooses local validation and a single-subagent review.
4. Existing AI/bot and optional subagent findings are independently checked against the current head before they can become findings.
5. Reviews prioritize the main flow and design boundaries; candidate findings are checked for reachability, concrete impact, change relevance, and confidence.
6. Code reviews and issue analysis load separate references; security guidance loads only for security-sensitive paths.
7. Full PR/MR reviews use a stable report structure; snippets and focused reviews stay concise.

## Contributing

Issues and PRs are welcome. If you want to add support for a new platform (Bitbucket, Gitea, etc.) or extend the security checklist for another language, please open an issue first.

**Local testing**:

```bash
# Test script robustness
bash scripts/fetch_pr.sh invalid-url          # Should show format error
bash scripts/fetch_issue.sh invalid-url        # Should show format error

# Test with a real PR (requires gh auth)
bash scripts/fetch_pr.sh https://github.com/owner/repo/pull/1

# Run local behavior tests
bash tests/scripts_test.sh

# Verify SKILL.md YAML frontmatter
head -10 SKILL.md
```

**Adding a new platform**: Create a new branch in `scripts/fetch_pr.sh` and `scripts/fetch_issue.sh` following the existing GitHub/GitLab pattern (CLI check, URL validation, metadata fetch, diff fetch).

## License

MIT

---

## 中文文档

一个面向 Codex 和 Claude Code 的证据优先代码审查 Skill。支持 GitHub/GitLab PR、diff、代码片段、commit、模块审查和 Issue 分析，强调可达路径、具体影响、置信度和简洁的合并建议。

### 审查深度与重点

对于线上 Issue 或 PR，Skill 会先读取描述、diff、评论、关联上下文和可见 CI，再一次询问两个互相独立的选择：是否拉取或检出代码进行本地验证，以及是否启用一个子 agent 独立复审。

- 轻量审查不会 clone、fetch、checkout，也不会运行本地测试。
- 用户同意本地验证后，Skill 会直接运行覆盖核心变更路径的最小相关测试；安装依赖、启动容器、访问外部服务或扩大本地环境影响仍需另行授权。
- 用户同意子 agent 复审后，只启用一个子 agent。它重点检查主执行流程、状态流转、模块边界、接口契约、错误路径、兼容性和设计取舍；主 agent 独立核验后才能采纳其结论。
- 格式、命名和一般风格偏好默认不作为主要审查目标。

### 安装

**一键安装（推荐）：**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/install.sh)
```

**手动安装：**

```bash
git clone https://github.com/googs1025/code-review-skill.git \
  ~/.claude/skills/code-review-skill
chmod +x ~/.claude/skills/code-review-skill/scripts/*.sh
```

**前置依赖：**
- [Claude Code](https://claude.ai/code)
- GitHub PR/Issue 审查需安装 [gh CLI](https://cli.github.com) 并 `gh auth login`
- GitLab MR/Issue 审查需安装 [glab CLI](https://gitlab.com/gitlab-org/cli) 并 `glab auth login`

### 使用

```
# 审查 GitHub PR
/code-review-skill https://github.com/owner/repo/pull/123

# 审查 GitLab MR
/code-review-skill https://gitlab.com/group/project/-/merge_requests/456

# 分析 GitHub Issue
/code-review-skill https://github.com/owner/repo/issues/456

# 粘贴 diff 或代码片段直接分析
/code-review-skill
```

### 更新

```bash
cd ~/.claude/skills/code-review-skill && git pull
```

### 卸载

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/uninstall.sh)
```

或手动删除：

```bash
rm -rf ~/.claude/skills/code-review-skill
```

仅删除 `code-review-skill` 目录，不影响 `~/.claude/skills/` 下的其他 skill。
