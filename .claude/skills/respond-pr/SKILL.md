---
name: respond-pr
description: Draft responses to unresolved PR review comments. Use when asked to respond to or address PR feedback.
---

# /respond-pr — Draft PR Comment Responses

Input: `$ARGUMENTS` (PR number). Delegates to the **github** agent workflow.

1. Fetch comments, identify unresolved threads
2. Read referenced code for context
3. Draft responses — present all to user for approval before posting
