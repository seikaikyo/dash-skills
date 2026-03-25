---
name: plan
description: "Create planning files (task_plan.md, findings.md, progress.md) for a new task"
allowed-tools:
  - Read
  - Write
  - Glob
---

# /plan -- Create Planning Files

Create the three planning files for a new task.

## Steps

1. Check if planning files already exist in the project root:
   - `task_plan.md`
   - `findings.md`
   - `progress.md`

2. If any exist, ask the user before overwriting. Show which files
   were found and confirm they want to start fresh.

3. Ask the user: "What is the goal of this task?" Use their response
   as the Goal in `task_plan.md`.

4. Create all three files using the templates from
   `{baseDir}/skills/planning-with-files/references/templates.md`.
   Fill in:
   - The Goal section with the user's response
   - The Session date in `progress.md` with today's date
   - Phase titles if the user described their task in enough detail

5. Display a summary:
   ```
   Planning files created:
   - task_plan.md  (phases and progress tracking)
   - findings.md   (research and decisions)
   - progress.md   (session log)

   Current phase: Phase 1 - Requirements & Discovery
   ```
