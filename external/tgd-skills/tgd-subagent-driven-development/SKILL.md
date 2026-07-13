---
name: tgd-subagent-driven-development
description: Execute implementation plans by dispatching fresh subagents per task with two-stage review. Use when executing a multi-task implementation plan, when context is getting too long for quality output, or when you want maximum isolation between tasks.
---

# Subagent-Driven Development

## Overview

Execute implementation plans by dispatching **fresh subagents per task** with two-stage review: **spec compliance first, then code quality**.

**Core Principle:** Fresh subagent per task + two-stage review = high quality, fast iteration

**Why Subagents:**
- Each task gets a clean context window — no pollution from prior tasks
- Subagents receive precisely crafted instructions — focus and success
- Your main context is preserved for coordination — you stay in control
- Quality doesn't degrade as context grows — every task starts fresh

## When to Use

- Executing a multi-task implementation plan (TASKS.md)
- Context is getting long and output quality is degrading
- Tasks are mostly independent (can be executed sequentially)
- You want the highest quality output per task

**When NOT to use:**
- Single, small changes (use `tgd-incremental-implementation` instead)
- Tasks that are tightly coupled and need constant cross-reference
- Exploration/prototyping where you don't have a plan yet

## The Process

```
Read TASKS.md
    │
    ▼
┌─ For each task ──────────────────────────────────────┐
│                                                       │
│  1. Dispatch implementer subagent                     │
│     - Provide: task spec, relevant files, context     │
│     - Subagent implements, tests, commits             │
│                                                       │
│  2. Dispatch spec reviewer subagent                   │
│     - Provide: task spec + subagent's output          │
│     - Checks: does code match the spec?               │
│     - If NO → fix round (see Review FAIL loop below)  │
│                                                       │
│  3. Dispatch code quality reviewer subagent           │
│     - Provide: code diff + quality checklist           │
│     - Checks: readability, patterns, test quality     │
│     - If NO → fix round (see Review FAIL loop below)  │
│                                                       │
│  4. Flip the task's **Status:** line to `complete`    │
│     in TASKS.md (+ backfill Test: fields)             │
│                                                       │
└───────────────────────────────────────────────────────┘
    │
    ▼
Final review of entire implementation
```

**Review FAIL loop (bounded):** the original implementer subagent is gone —
fresh context is the point. On FAIL, the orchestrator dispatches a NEW
implementer subagent with the same task spec PLUS the reviewer's specific
FAIL list. **Maximum two fix rounds per review stage.** If the third review
still FAILs, do not keep ping-ponging: set the task's `**Status:** blocked:
review deadlock — <one-line summary>` in TASKS.md, record the disagreement
under `## Risks & Mitigations`, and move to the next task. A deadlock usually
means the spec is ambiguous — that's a human call, not a longer loop.

## Continuous Execution

**Do not pause to check in between tasks.** Execute all tasks from the plan without stopping.

**Only reasons to stop:**
- BLOCKED status you cannot resolve
- Ambiguity that genuinely prevents progress
- All tasks complete

**Never:** Use "Should I continue?" prompts or progress summaries — waste the user's time.

## Subagent Prompts

### Implementer Prompt Template

```
You are implementing a single task from an implementation plan.

WORKING DIRECTORY:
{worktree_path}   ← all reads, writes, and commands happen HERE
                    (the isolated worktree, not the main checkout;
                    for a [repo-name]-tagged task this is THAT repo's
                    worktree — ../project-<feature>-<repo-name>)

TASK:
{task_description_including_AC_ids}

RELEVANT FILES:
{file_list}

CONTEXT:
{relevant_context}

RULES:
1. Implement exactly what the task specifies — nothing more, nothing less
2. Write tests before code (TDD Red-Green-Refactor)
3. Every test verifying a criterion MUST mention its AC-<task>.<n> id in
   the test name, docstring, or a comment — this is machine-checked later
4. Commit when the task is complete with a clear commit message
5. Do NOT modify files outside your task scope
6. If you encounter ambiguity, state it clearly and stop
7. If you find a bug OUTSIDE your task scope: do NOT fix it — report it
   in your output (file, symptom, suspected cause) and keep going. The
   orchestrator decides whether it becomes a new task.

EXPECTED OUTPUT:
- Code changes committed
- Tests written and passing
- For EACH acceptance criterion: the AC id and the test file path that
  verifies it (the orchestrator records these in TASKS.md Test: fields)
- Out-of-scope bugs found, if any (file + symptom + suspected cause)
- Brief summary of what was done
```

**Orchestrator duty after each implementer completes:** take the AC-id → test-path
pairs from the output and backfill the `Test:` fields in
`$TGD_DIR/<feature-name>/TASKS.md`, then flip that task's `**Status:**` line
from `in-progress` to `complete`. If the output reports out-of-scope bugs, record
each under `## Risks & Mitigations` (or add a new task if it must be fixed this
cycle) — do NOT let the report evaporate. Subagents cannot reliably write
outside the worktree — the orchestrator owns the artifacts directory.

**Orchestrator duty after each review stage:** record the outcome in the task's
`Spec-Review:` / `Quality-Review:` fields in TASKS.md — `PASS — <one line>` or
`FAIL — <one line>` (after a FAIL: implementer fixes, the stage re-runs, then
flip to PASS). If you cannot dispatch reviewer subagents, run both review
stages INLINE against their prompt templates — inability to delegate never
skips a stage — and record the fields the same way. `/tgd-verify` fails closed
on a completed task whose review fields still read `pending`.

### Spec Reviewer Prompt Template

```
You are reviewing code for spec compliance.

TASK SPEC:
{task_description}

CODE CHANGES:
{diff_or_file_list}

CHECK:
1. Does the code implement everything the spec requires?
2. Are there any spec requirements that were missed?
3. Does the code do anything NOT in the spec? (scope creep)
4. Are edge cases from the spec handled?

OUTPUT:
- PASS: Code matches spec
- FAIL: List specific gaps between spec and implementation
```

### Code Quality Reviewer Prompt Template

```
You are reviewing code for quality.

CODE CHANGES:
{diff_or_file_list}

CHECK:
1. Readability: Is the code clear and well-structured?
2. Patterns: Does it follow existing codebase conventions?
3. Test quality: Are tests meaningful (not just for coverage)?
4. Error handling: Are failure cases handled?
5. Performance: Any obvious performance issues?
6. Security: Any obvious security issues?

OUTPUT:
- PASS: Code meets quality standards
- FAIL: List specific issues with severity (critical/important/nit)
```

## Integration with tGD

This skill is invoked by `/tgd-develop` when executing a task plan. It replaces the default single-session execution with subagent-based execution for higher quality.

**Trigger conditions:**
- TASKS.md exists with multiple tasks
- Tasks are mostly independent
- User wants maximum quality (not maximum speed)

**Fallback:** If subagent delegation is not available, fall back to `tgd-incremental-implementation`.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just do it in this session" | Context pollution degrades quality per task |
| "Subagents will mess it up" | Fresh context + clear spec = higher quality |
| "Two-stage review is overkill" | Spec compliance + code quality catch different bugs |
| "It's faster without review" | Faster now, slower when bugs surface later |

## Red Flags

- Subagent output claims "done" without showing diff or test results
- Skipping spec review and going straight to code review
- Modifying files outside the task scope
- Implementer and reviewer getting the same overly broad context
- Reviewer passes without listing specific checks performed

## Verification

- [ ] Each subagent produced verifiable output (diff, test results, or commit SHA)
- [ ] Spec reviewer confirmed all requirements met (PASS or gaps listed)
- [ ] Code quality reviewer found no critical issues
- [ ] Tests are tagged with their `AC-<task>.<n>` ids and TASKS.md `Test:` fields are backfilled
- [ ] Every task's `**Status:**` line reads `complete` (or `blocked: <ref>` with the blocker recorded — never left `pending`)
- [ ] Out-of-scope bug reports from implementers were recorded in Risks & Mitigations, not dropped
- [ ] Final integration test passes
