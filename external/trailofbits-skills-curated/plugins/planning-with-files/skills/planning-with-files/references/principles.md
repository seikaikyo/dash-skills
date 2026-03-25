# Context Engineering Principles

The principles behind file-based planning, distilled from Manus's
context engineering approach.

## Filesystem as External Memory

```
Context Window = RAM (volatile, limited)
Filesystem     = Disk (persistent, unlimited)
```

Anything important gets written to disk. The context window is
temporary -- it resets, it fills up, it loses older content. Files
persist across sessions, have no size limit, and can be selectively
re-read when needed.

When compressing context (summarizing, dropping details), always
preserve pointers to the full data: keep URLs even if web content
is dropped, keep file paths when dropping document contents. Never
lose the ability to recover the original.

## Manipulate Attention Through Recitation

This is the key insight behind the entire approach.

After ~50 tool calls, models forget original goals. This is the
"lost in the middle" effect -- content at the start and end of the
context window gets attention, but the middle fades.

The fix: re-read `task_plan.md` before each major decision. This
pushes the goal and current state into the most recent part of the
context, where it gets maximum attention.

```
Start of context: [Original goal -- far away, low attention]
...many tool calls in the middle...
End of context: [Recently read task_plan.md -- HIGH attention]
```

This is why Manus can handle ~50 tool calls without losing track.
The plan file acts as a goal-refresh mechanism.

## Keep the Wrong Turns In

Leave failed attempts and error traces in the planning files.

Why:
- Failed actions with stack traces let the model implicitly update
  its beliefs about what works
- Reduces repetition of the same mistakes
- Error recovery is one of the clearest signals of effective
  agentic behavior

The error table in `task_plan.md` serves this purpose. Log every
failure with the attempt number and what you tried. The next attempt
should always be different.

## Avoid Repetitive Patterns

Repetitive action-observation pairs cause drift and hallucination.
When you notice yourself doing the same thing repeatedly:

- Vary your approach (different tool, different angle)
- Re-read the plan to check if you're still on track
- If stuck after 3 attempts, escalate to the user

## Context Offloading

Store full results on disk, keep only references in context.

Practical application:
- Write large search results or API responses to files
- Keep file paths and summaries in context
- Use `glob` and `grep` to find information later
- Load details only when needed (progressive disclosure)

This keeps the context window focused on the current task while
making all accumulated knowledge accessible through the filesystem.

## Source

Based on context engineering principles from
[Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus).
