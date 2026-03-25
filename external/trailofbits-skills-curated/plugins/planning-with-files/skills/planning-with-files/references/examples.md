# Examples

## Bug Fix Task

**User request:** "Fix the login bug in the authentication module"

### task_plan.md after Phase 3

```markdown
# Task Plan: Fix Login Bug

## Goal
Identify and fix the bug preventing successful login.

## Phases

### Phase 1: Understand the bug report
- [x] Review bug report details
- **Status:** complete

### Phase 2: Locate relevant code
- [x] Search for auth handler
- **Status:** complete

### Phase 3: Identify root cause
- [ ] Trace the TypeError
- **Status:** in_progress

### Phase 4: Implement fix
- [ ] Fix the async/await issue
- **Status:** pending

### Phase 5: Test and verify
- [ ] Run auth test suite
- **Status:** pending

## Key Questions
1. What error message appears?
2. Which file handles authentication?
3. What changed recently?

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Auth handler is in src/auth/login.ts | Grep found validateToken() here |
| Root cause: user object not awaited | TypeError trace pointed to line 42 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| TypeError: Cannot read property 'token' of undefined | 1 | Found: user object not awaited properly |
```

Key points:
- Phases are broken into discoverable steps
- Decisions record WHERE and WHY, not just WHAT
- The error table captures the actual trace, not a vague description

## Error Recovery Pattern

When something fails, don't hide it. Log it and change approach.

### Wrong approach

```
Action: Read config.json
Error: File not found
Action: Read config.json     <- silent retry, same action
Action: Read config.json     <- another retry, still same action
```

Three identical attempts, no learning, no progress.

### Correct approach

```
Action: Read config.json
Error: File not found

Update task_plan.md:
  ## Errors Encountered
  | Error | Attempt | Resolution |
  |-------|---------|------------|
  | config.json not found | 1 | Will create default config |

Action: Write config.json (create with defaults)
Action: Read config.json
Success!
```

The error is logged, the approach mutates, and progress is made.
This is Rule 6 (Never Repeat Failures) in action.

## The Read-Before-Decide Pattern

This is the most important pattern in file-based planning.

```
[Many tool calls have happened...]
[Context is long, original goal is fading...]

-> Read task_plan.md           <- brings goals back into attention
-> Now make the decision       <- goals are fresh in context
```

When to apply:
- Before choosing between implementation approaches
- Before starting a new phase
- After a long sequence of search/read operations
- Whenever you feel uncertain about the current direction

The plan file is not just a record -- it is an active tool for
maintaining focus across long task sequences.
