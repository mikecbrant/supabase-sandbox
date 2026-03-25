---
name: review-pr
description: Fetch PR data and perform a structured code review. Use when asked to review a pull request or analyze PR changes.
---

# /review-pr — Structured PR Review

Input: `$ARGUMENTS` (PR number). Delegates to the **github** agent workflow.

## Output Format

- **Summary**: One-line description of what the PR does
- **Changes Overview**: Key changes by file/area
- **Issues Found**: Grouped by severity (blocking / suggestions / nits) with file:line references and suggested fixes
- **What Looks Good**: Briefly note well-done aspects

Do NOT post comments to GitHub without explicit user approval.
