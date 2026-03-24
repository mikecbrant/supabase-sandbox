---
name: git
description: Analyze git state and prepare commits. Use when the user asks to review changes, prepare a commit, compare branches, or check what's been modified.
---

# /git — Git State Analysis

1. Show current state: `git status`, `git diff --stat`, `git log --oneline -10`
2. If staged changes exist, show `git diff --cached`
3. If on a feature branch, show divergence from main
4. Summarize: branch, staged vs unstaged changes, untracked files, suggested next action

## Committing

- Draft a commit message from the staged diff — present for approval before running `git commit`
- Never amend commits or force push without explicit approval
