# oss-code-review

A Claude Code skill that turns Claude into a senior open-source code reviewer. Supports GitHub/GitLab PR links, raw diffs, code snippets, and commit history — outputs a structured report with Critical/Major/Minor issue grading and a final merge recommendation.

[中文文档](#中文文档)

---

## Features

- **Auto-detects input type** — PR URL, diff, code snippet, or commit range
- **4-dimension analysis** — Code Quality, Security, Performance, OSS Compliance
- **Severity grading** — 🔴 Critical / 🟠 Major / 💡 Minor
- **Structured output** — consistent report format every time
- **GitHub & GitLab** — works with both platforms via `gh` and `glab` CLIs
- **Language-aware** — security checklist covers Go, Python, JS/TS, Rust, Java

## Installation

### One-line install (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/oss-code-review/main/scripts/install.sh)
```

### Manual install

```bash
git clone https://github.com/googs1025/oss-code-review.git \
  ~/.claude/skills/oss-code-review
chmod +x ~/.claude/skills/oss-code-review/scripts/*.sh
```

### Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| [Claude Code](https://claude.ai/code) | ✅ Yes | The CLI that runs this skill |
| [gh CLI](https://cli.github.com) | For GitHub PRs | Fetch PR metadata and diff |
| [glab CLI](https://gitlab.com/gitlab-org/cli) | For GitLab MRs | Fetch MR metadata and diff |

Make sure you're authenticated:

```bash
gh auth login    # GitHub
glab auth login  # GitLab
```

## Usage

After installation, use the `/oss-code-review` slash command in Claude Code:

```
# Review a GitHub PR
/oss-code-review https://github.com/owner/repo/pull/123

# Review a GitLab MR
/oss-code-review https://gitlab.com/group/project/-/merge_requests/456

# Review a pasted diff or code snippet
/oss-code-review
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
cd ~/.claude/skills/oss-code-review && git pull
```

Or re-run the one-line installer.

## File structure

```
oss-code-review/
├── SKILL.md                        # Skill prompt (loaded by Claude Code)
├── scripts/
│   ├── fetch_pr.sh                 # Fetch PR/MR metadata and diff
│   ├── fetch_commits.sh            # Fetch commit history
│   └── install.sh                  # One-command installer
└── references/
    └── security_checklist.md       # Per-language security checklist
```

## How it works

1. Claude Code detects `/oss-code-review` and loads `SKILL.md` as the system prompt
2. If a PR URL is provided, Claude runs `scripts/fetch_pr.sh` via Bash to fetch metadata and the full diff using the `gh` or `glab` CLI
3. Claude analyzes the diff across 4 dimensions, referencing `references/security_checklist.md` for security issues
4. Claude outputs the structured report

## Contributing

Issues and PRs are welcome. If you want to add support for a new platform (Bitbucket, Gitea, etc.) or extend the security checklist for another language, please open an issue first.

## License

MIT

---

## 中文文档

一个 Claude Code Skill，让 Claude 化身资深开源代码 Reviewer。支持 GitHub/GitLab PR 链接、原始 diff、代码片段和 commit 历史，输出结构化审查报告，包含 Critical/Major/Minor 问题分级和最终合并建议。

### 安装

**一键安装（推荐）：**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/googs1025/oss-code-review/main/scripts/install.sh)
```

**手动安装：**

```bash
git clone https://github.com/googs1025/oss-code-review.git \
  ~/.claude/skills/oss-code-review
chmod +x ~/.claude/skills/oss-code-review/scripts/*.sh
```

**前置依赖：**
- [Claude Code](https://claude.ai/code)
- GitHub PR 审查需安装 [gh CLI](https://cli.github.com) 并 `gh auth login`
- GitLab MR 审查需安装 [glab CLI](https://gitlab.com/gitlab-org/cli) 并 `glab auth login`

### 使用

```
# 审查 GitHub PR
/oss-code-review https://github.com/owner/repo/pull/123

# 审查 GitLab MR
/oss-code-review https://gitlab.com/group/project/-/merge_requests/456

# 粘贴 diff 或代码片段直接分析
/oss-code-review
```

### 更新

```bash
cd ~/.claude/skills/oss-code-review && git pull
```
