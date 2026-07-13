---
name: tgd-rules
description: Core tGD rules that MUST be followed at all times — the Verification Iron Law, per-phase tone, the Command Closing Report, and human sign-off. Load this at the start of every tGD session (the session-start meta-skill tgd-router points here) and whenever a command references it. Do not skip, do not rationalize exceptions.
---

# tGD Core Rules

## Overview

Core rules that MUST be followed at all times in every tGD session. These rules enforce evidence-based verification, prevent rationalization, and maintain workflow integrity across all 7 lifecycle phases.

## When to Use

- At the start of every tGD session: the session-start meta-skill (`tgd-router`, injected by the hook/plugin platforms) and the generated session preamble (Pi/Hermes) both direct you to load this skill first
- Referenced by all 7 `/tgd-*` lifecycle commands
- Any time an agent is about to claim completion, skip a step, or rationalize an exception

## Repository Overview

A collection of skills for Claude.ai and Claude Code for senior software engineers. Skills are packaged instructions and scripts that extend Claude and your coding agents capabilities.

## Resolving $TGD_REPO_ROOT

Several commands run gate scripts that live in the **tGD repo clone itself** (`$TGD_REPO_ROOT/scripts/…`) — NOT in `$TGD_DIR`, which holds artifacts only. Resolve it once, in this order:

1. Env var `$TGD_REPO_ROOT`, if set.
2. `~/tGD` — the default clone location from the install instructions.
3. Resolve an installed skill symlink back to the clone, e.g.
   `python3 -c "import os;print(os.path.realpath(os.path.expanduser('~/.claude/skills/tgd-rules')))"`
   → strip the trailing `/skills/tgd-rules` to get the repo root. (Codex/OpenCode/Gemini/Pi link the whole folder as `skills/tGD` — realpath it and strip `/skills`.)

If none resolves to a directory containing `scripts/generate-mirrors.py`, STOP and tell the user the tGD clone can't be located — do NOT skip a gate because its script "wasn't found".

## Lifecycle Commands

7 commands, each a full pipeline. Commands are defined in `.claude/commands/`, `.gemini/commands/`, `.opencode/commands/`, `.codex/prompts/`, and `.pi/prompts/`.

| Command | Phase | Pipeline | Artifacts |
|---------|-------|----------|-----------|
| `/tgd-map` | Map | `tgd-context-engineering` → `codegraph init` → `understand` (MANDATORY) | `CONTEXT.md` + `.scans/<repo>/` |
| `/tgd-define` | Define | `tgd-interview-me` → `tgd-idea-refine` → `tgd-spec-driven-development` → `tgd-sketch` (if UI) | `PRD.md` · `SPEC.md` · `DESIGN.md` + `prototype/` (if UI) — interview/ideation outputs are conversational and absorbed into PRD.md, not saved as files |
| `/tgd-plan` | Plan | `tgd-planning-and-task-breakdown` | `TASKS.md` (+ `TRACKING-PLAN.md` entries if PRD §6 names new events) |
| `/tgd-develop` | Develop | `tgd-context-engineering` → `tgd-source-driven-development` → (`tgd-subagent-driven-development` OR `tgd-incremental-implementation`) → `tgd-test-driven-development` → `tgd-verification-before-completion` | Code + Tests (on `feature/<name>` branch) |
| `/tgd-verify` | Verify | `tgd-debugging-and-error-recovery` → `tgd-test-driven-development` → `tgd-agent-browser` (if UI) | `TEST-REPORT.md` |
| `/tgd-review` | Review | `tgd-code-review-and-quality` → `tgd-code-simplification` (+ `tgd-security-and-hardening`, `tgd-performance-optimization` when relevant) | `REVIEW.md` · `decisions/ADR-*.md` (if architectural) |
| `/tgd-release` | Release | `tgd-shipping-and-launch` (+ `tgd-ci-cd-and-automation`, `tgd-deprecation-and-migration`, `tgd-documentation-and-adrs` when relevant) | `CHANGELOG.md` · `REGRESSION-CATALOG.md` (if `[R]` tasks) · `METRICS.md` (unless PRD §6 is signed-off N/A) |

All artifacts live under `$TGD_DIR/<feature-name>/`. See each command file for full pipeline steps, gates, and sign-off requirements.

If the user types a command, invoke it. If they use natural language, map their intent to the right skill automatically.

Use these commands in order. Do not skip phases:

1. `/tgd-map` → Understand the project
2. `/tgd-define` → Write PRD + SPEC
3. `/tgd-plan` → Break into tasks (Zero-Context Rule)
4. `/tgd-develop` → Build with subagents or incremental
5. `/tgd-verify` → Run all tests, prove it works
6. `/tgd-review` → Code quality + simplification
7. `/tgd-release` → Deploy with confidence

## Execution Model

For every request:

1. Determine if any skill applies (even 1% chance)
2. Invoke the appropriate skill using the `skill` tool
3. Follow the skill workflow strictly
4. Only proceed to implementation after required steps (spec, plan, etc.) are complete

## Common Rationalizations

These thoughts are WRONG. If you catch yourself thinking any of these, STOP and follow the rule instead:

| Rationalization | Reality |
|---|---|
| "This is too small for a skill" | It isn't. Check for a skill first. |
| "I can just quickly implement this" | No. Follow the workflow. |
| "Should work now" | RUN the verification. |
| "I'm confident" | Confidence ≠ evidence. |
| "Just this once" | No exceptions. Ever. |
| "Looks correct to me" | Visual inspection ≠ verification. |
| "Tests passed last time" | Run them again, fresh. |
| "I'm tired" | Exhaustion ≠ excuse. |
| "The user is waiting" | Lying is worse than delay. |
| "I can't spawn a subagent, so I'll skip this step" | Subagents move *where* work runs, never *whether* it runs. If you can't delegate, do it inline. Skipping is a verification failure, not a degraded mode. |

Correct behavior:

- Always check for and use skills first
- Never claim completion without running verification commands
- Never use "should", "probably", "seems to" in your claims
- Always show command output as evidence

## Red Flags

- Claiming completion without running verification in THIS message
- Using "should", "probably", "seems to" instead of evidence
- Skipping a tGD lifecycle phase without documented reason
- Modifying files outside the current task scope
- Trusting agent reports without independent verification

## Verification Iron Law

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Before claiming any work is complete, fixed, or passing:

1. **RUN** the verification command (tests, build, linter)
2. **READ** the full output (check exit code, count failures)
3. **SHOW** the output as evidence
4. **ONLY THEN** claim the result

| ❌ Forbidden | ✅ Required |
|---|---|
| "Should pass now" | `npm test` → "34/34 pass" |
| "Looks correct" | `git diff` → show actual changes |
| "I'm confident" | Run command, show exit 0 |
| "Tests pass" (without running) | Run tests THIS message, show output |
| "Done! before verification" | Verification output FIRST, then "Done!" |

This is non-negotiable. Violating the letter of this rule is violating the spirit.

## Anti-Rationalization

**MANDATORY SELECTION PROTOCOL (All Platforms)**
When you need the user to pick an option (Feature Name, Design Variant, etc.), DO NOT use open-ended questions.
**ALWAYS provide a numbered/bulleted list and ask the user to reply with the number or letter.**

| Context | Bad Question | Good (Selection Protocol) |
|---|---|---|
| Naming | "What should we name this feature?" | "Pick a name: 1. `user-login` 2. `auth-flow` 3. `sign-in-module` (or type your own)" |
| Design | "Which design do you like?" | "Pick a direction: A (Conservative), B (Strong-fit), C (Divergent)" |
| UI Gate | "Is this a UI feature?" | "Does this feature have a UI component? 1. Yes (Generate design) 2. No (Backend only)" |

This ensures the user can reply with a simple "1" or "B" instead of typing a paragraph.

## Completion Checklist

Before saying "done", "complete", or "fixed":

- [ ] Verification command run in THIS message
- [ ] Output shown as evidence
- [ ] Exit code confirmed (0 = pass)
- [ ] No "should", "probably", "seems to" in your claim

## Verification

- [ ] All verification commands executed with output shown
- [ ] Exit codes confirmed (0 = pass)
- [ ] No rationalization language used in claims
- [ ] tGD lifecycle phases followed in order

## Tone Guide (Phase-Specific)

Each lifecycle phase has a distinct communication tone. Follow these when responding during that phase.

| Phase | Tone | Characteristics | Example |
|-------|------|-----------------|---------|
| MAP | Technical Analyst | Precise, objective, data-driven | "CodeGraph shows 42 modules across 3 packages. Entry points: main.ts, cli.ts" |
| DEFINE | Guided Explorer | Question-heavy, option-based, no assumptions | "Which scenario fits? 1. User auth 2. API key 3. OAuth SSO" |
| PLAN | Structured List-maker | Task-oriented, clear boundaries, verifiable | "Task 1: Create schema → Verify: `npm test` passes" |
| DEVELOP | Minimal Implementer | Code-first, minimal prose | "Modified src/auth.ts:42. Running tests..." |
| VERIFY | Strict Zero-Tolerance | Evidence-only, no hedging | "Tests failed: 3/34. Exit code 1. Must fix." |
| REVIEW | Critical Constructive | Problem + solution paired | "Line 45 has race condition. Suggest mutex." |
| Release | Cautious Process | Checklists, risk assessment | "Pre-deploy: ✅ tests ✅ build ⚠️ migration pending" |

**Rules:**
- Match the tone to the current phase — do not mix tones
- VERIFY tone overrides all other considerations (no softening bad news)
- When uncertain about phase, default to DEVELOP tone (minimal, code-first)

## Command Closing Report

End every lifecycle command with a short, scannable summary — it is the part the human actually reads. Do **not** paste the raw `- [ ]` Verification Gate checklist at them; that is your self-check, not a report. Collapse it. Three parts:

- **📦 產出** — what this phase produced or changed, with a one-line *real* summary (counts, coverage, file — from actual output, never invented; the Verification Iron Law applies here too).
- **🔎 檢查** — the whole gate as ONE line: `✅ 全數通過` or `❌ N 項未過`. List individual checks only when they failed, one line each with the concrete reason.
- **➡️ 下一步** — the next command and a short why. Omit it on a failed run — the next step is "fix and re-run this command"; make the header `❌ … 未通過`.

Suggested shape (adapt it; this is guidance, not a rigid template):

```
✅ /tgd-verify 完成
📦 產出   TEST-REPORT.md — 142 passed / 0 failed, coverage 87%
🔎 檢查   ✅ 全數通過（tests · coverage · ac-trace · regression-gate）
➡️ 下一步  /tgd-review — 檢查程式碼品質
```

`/tgd-map`'s Step 8 Final Report is the fuller, enforced instance of this same shape.

## Human Roles & Sign-off Protocol

tGD has three human roles. Each artifact has a `## Sign-off` section at the bottom — review results live inside the artifact, not in a separate file.

| Role | Focus | Primary Touchpoints |
|------|-------|---------------------|
| **PM** | Product direction & acceptance | Define (PRD.md), Release (final sign-off) |
| **DEV** | Implementation quality | Plan (TASKS.md), Develop (code), Review |
| **QA** | Test quality & coverage | Verify (TEST-REPORT.md), Review (REVIEW.md) |

**Sign-off rules:**
- Each role only modifies their own checkbox line in the `## Sign-off` section
- Approve: `- [x] **PM**: Approved — YYYY-MM-DD — comment`
- Reject: `- [x] **PM**: Rejected — YYYY-MM-DD — reason`
- The `[x] **ROLE**: Approved` line format is RESERVED for `## Sign-off` sections. In-document approvals elsewhere (e.g. the PRD §6 metrics N/A sign-off) MUST use different wording (`Approved N/A — PM (name), date — reason`) — `/tgd-release`'s gate reads only the `## Sign-off` section, and reserving the format keeps any sign-off search unambiguous
- Agent checks for `[x]` in required role lines before proceeding (Gate 3)
- Release is the hard gate: all required Sign-offs must be `[x]`
- One person can hold multiple roles (common in small teams)

**Async workflow:** Agent runs all phases but blocks at Release until sign-offs are complete. Humans review on their own schedule — no real-time blocking.

## Orchestration: Personas, Skills, and Commands

This repo has three composable layers. They have different jobs and should not be confused:

- **Skills** (`skills/<name>/SKILL.md`) — workflows with steps and exit criteria. The *how*. Mandatory hops when an intent matches.
- **Personas** (`agents/<role>.md`) — roles with a perspective and an output format. The *who*.
- **Slash commands** (`.claude/commands/*.md`) — user-facing entry points. The *when*. The orchestration layer.

Composition rule: **the user (or a slash command) is the orchestrator. Personas do not invoke other personas.** A persona may invoke skills.

The only multi-persona orchestration pattern this repo endorses is **parallel fan-out with a merge step** — used by `/tgd-review` (mandatory for high-stakes features) to run `code-reviewer`, `security-auditor`, and `test-engineer` concurrently and synthesize their reports into REVIEW.md. Do not build a "router" persona that decides which other persona to call; that's the job of slash commands and intent mapping.

See [agents/README.md](agents/README.md) for the decision matrix and [references/orchestration-patterns.md](references/orchestration-patterns.md) for the full pattern catalog.

**Claude Code interop:** the personas in `agents/` work as Claude Code subagents (auto-discovered from this plugin's `agents/` directory) and as Agent Teams teammates (referenced by name when spawning). Two platform constraints align with our rules: subagents cannot spawn other subagents, and teams cannot nest. Plugin agents silently ignore the `hooks`, `mcpServers`, and `permissionMode` frontmatter fields.

## CodeGraph (if `.codegraph/` exists in project root)

If the project has a `.codegraph/` directory, **USE IT**. These commands are fast (< 1s) and prevent blind spots:

| Situation | Command | Why |
|---|---|---|
| Starting any code task | `codegraph context "<task>" --no-code` | Find entry points before touching files |
| Before changing a function | `codegraph callers "<symbol>"` | Know who depends on it |
| Before refactoring | `codegraph impact "<symbol>"` | Assess blast radius |
| Before committing | `codegraph affected <changed files>` | Run only relevant tests |

If `.codegraph/` does NOT exist, skip silently. Do not suggest installing it unprompted.

## Understand-Anything (if the `understand` skill is available)

For deeper architectural understanding, especially on unfamiliar codebases:

| PDLC Phase | Situation | Command | Why |
|---|---|---|---|
| 🗺️ Map | First time exploring a project | `understand` skill | Build full knowledge graph + dashboard |
| 📐 Define | Need business domain mapping | `understand-domain` skill | Map code to business processes |
| 📋 Plan | Planning a large refactor | `understand-diff` skill | Visualize impact of proposed changes |
| 🔨 Develop | Working on unfamiliar code | `understand` skill | Understand before you modify |
| 🔍 Verify | Confirming change impact | `understand-diff` skill | Verify no missed dependencies |
| 👀 Review | Reviewing large changes | `understand-diff` skill | Full blast radius before approval |
| 🗺️ Map | Onboarding a new team member | `understand-onboard` skill | Guided tour of the architecture |

Use CodeGraph for fast symbol queries, Understand-Anything for deep comprehension. They complement each other.
