# code-review-skill

A Claude Code skill that turns Claude into a senior open-source code reviewer. Supports GitHub/GitLab PR links, raw diffs, code snippets, commit history, and issue analysis — outputs a structured report with Critical/Major/Minor issue grading and a final merge recommendation.

[中文文档](#中文文档)

---

## Features

- **Auto-detects input type** — PR URL, diff, code snippet, commit range, or issue link
- **Issue analysis** — paste a GitHub/GitLab issue URL, get problem analysis and solution ideas
- **4-dimension analysis** — Code Quality, Security, Performance, Open-Source Compliance
- **Severity grading** — 🔴 Critical / 🟠 Major / 💡 Minor
- **Structured output** — consistent report format every time
- **GitHub & GitLab** — works with both platforms via `gh` and `glab` CLIs
- **Language-aware** — security checklist covers Go, Python, JS/TS, Rust, Java

## Installation

### One-line install (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/code-review-skill/main/scripts/install.sh)
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
| [Claude Code](https://claude.ai/code) | ✅ Yes | The CLI that runs this skill |
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

After installation, use the `/code-review-skill` slash command in Claude Code:

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

### Example output

```
## 📋 Review 概览
- **变更类型**: 新功能
- **风险等级**: 🟠 中
- **变更摘要**: 为 PD 分离路由新增 TensorRT-LLM 引擎支持，同时重构重复的 prefill 逻辑为公共 helper。
- **受影响模块**: pd_disaggregation.go, pd_disaggregation_test.go

---

## 🚨 Critical Issues
✅ 无 Critical 问题

## ⚠️ Major Issues
### PD YAML 中 prefill/decode 镜像版本不一致
- **位置**: `tensor-rt-pd.yaml:47` vs `:88`
- **问题描述**: prefill 固定 :1.0.0，decode 用 :latest
- **风险**: 版本错位导致 PD 协议不兼容
- **建议**: 统一为 :1.0.0

## 🏁 总体评价
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
└── references/
    └── security_checklist.md       # Per-language security checklist
```

## How it works

1. Claude Code detects `/code-review-skill` and loads `SKILL.md` as the system prompt
2. If a PR URL is provided, Claude runs `scripts/fetch_pr.sh` via Bash to fetch metadata and the full diff using the `gh` or `glab` CLI
3. If an issue URL is provided, Claude runs `scripts/fetch_issue.sh` to fetch issue details and comments
4. For PRs/diffs, Claude analyzes the code across 4 dimensions, referencing `references/security_checklist.md` for security issues; for issues, Claude performs problem analysis and suggests solutions
5. Claude outputs the structured report

## Contributing

Issues and PRs are welcome. If you want to add support for a new platform (Bitbucket, Gitea, etc.) or extend the security checklist for another language, please open an issue first.

**Local testing**:

```bash
# Test script robustness
bash scripts/fetch_pr.sh invalid-url          # Should show format error
bash scripts/fetch_issue.sh invalid-url        # Should show format error

# Test with a real PR (requires gh auth)
bash scripts/fetch_pr.sh https://github.com/owner/repo/pull/1

# Verify SKILL.md YAML frontmatter
head -10 SKILL.md
```

**Adding a new platform**: Create a new branch in `scripts/fetch_pr.sh` and `scripts/fetch_issue.sh` following the existing GitHub/GitLab pattern (CLI check, URL validation, metadata fetch, diff fetch).

## License

MIT

---

## 中文文档

一个 Claude Code Skill，让 Claude 化身资深开源代码 Reviewer。支持 GitHub/GitLab PR 链接、原始 diff、代码片段、commit 历史和 Issue 分析，输出结构化审查报告，包含 Critical/Major/Minor 问题分级和最终合并建议。

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
