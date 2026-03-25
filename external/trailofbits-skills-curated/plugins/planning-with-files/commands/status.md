---
name: status
description: "Show current task plan status and phase summary"
allowed-tools:
  - Read
  - Glob
---

# /status -- Show Task Status

Read `task_plan.md` and display a compact phase summary.

## Steps

1. Check if `task_plan.md` exists in the project root. If not,
   tell the user: "No task_plan.md found. Use /plan to create one."

2. Read `task_plan.md` and extract:
   - The Goal
   - Each phase title and its status

3. Display a compact summary using text markers:

   ```
   Goal: [goal statement]

   [done]    Phase 1: Requirements & Discovery
   [done]    Phase 2: Planning & Structure
   [current] Phase 3: Implementation
   [pending] Phase 4: Testing & Verification
   [pending] Phase 5: Delivery

   Progress: 2/5 phases complete
   ```

   Status mapping:
   - `complete` -> `[done]`
   - `in_progress` -> `[current]`
   - `pending` -> `[pending]`
   - Any phase with blockers noted -> `[blocked]`

4. If `findings.md` exists, also show a count of entries:
   ```
   Findings: 3 research items, 2 decisions, 1 issue
   ```
