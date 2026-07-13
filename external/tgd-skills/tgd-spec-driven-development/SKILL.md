---
name: tgd-spec-driven-development
description: Creates specs before coding. Use when starting a new project, feature, or significant change and no specification exists yet. Use when requirements are unclear, ambiguous, or only exist as a vague idea.
---

# Spec-Driven Development

## Overview

Write a structured specification before writing any code. The spec is the shared source of truth between you and the human engineer — it defines what we're building, why, and how we'll know it's done. Code without a spec is guessing.

## When to Use

- Starting a new project or feature
- Requirements are ambiguous or incomplete
- The change touches multiple files or modules
- You're about to make an architectural decision
- The task would take more than 30 minutes to implement

**When NOT to use:** Single-line fixes, typo corrections, or changes where requirements are unambiguous and self-contained.

## The Gated Workflow

Spec-driven development has four phases. Do not advance to the next phase until the current one is validated.

**Step 0: Feature Name Resolution**
Before writing any content, determine the `<feature-name>`:
0. **Existing-feature check first**: scan `$TGD_DIR/` for feature dirs (subdirs with `PRD.md`/`SPEC.md`). If one plausibly matches this ask, offer to revise it in place instead of minting a new name (same rule as `/tgd-define` step 3) — never silently create a duplicate directory for the same feature.
1. **Propose**: Based on the user's request, propose 3 distinct kebab-case `<feature-name>` options with brief descriptions (e.g., "user-auth", "login-system", "access-control").
2. **Wait**: Ask the user to pick one or provide their own. Do NOT proceed until the name is locked.
3. **Create directory**: `mkdir -p $TGD_DIR/<feature-name>/`.
4. **Verify**: If `$TGD_DIR/<feature-name>/` already exists, use it. If not, the previous step must have created it.
5. **Lock**: Use this exact `<feature-name>` for all subsequent files (PRD.md, SPEC.md, TASKS.md, etc.).

**🌿 No git operations in this phase.** PRD/SPEC live in `$TGD_DIR` (outside the code repo) — there is nothing to commit yet. The `feature/<feature-name>` branch is created by `/tgd-develop`'s worktree step (`git worktree add -b`); creating and checking it out here would make that step fail, because git refuses to check out a branch that is already checked out in another worktree.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

### Phase 1: Specify

Start with a high-level vision. Ask the human clarifying questions until requirements are concrete.

**Surface assumptions immediately.** Before writing any spec content, list what you're assuming:

```
ASSUMPTIONS I'M MAKING:
1. This is a web application (not native mobile)
2. Authentication uses session-based cookies (not JWT)
3. The database is PostgreSQL (based on existing Prisma schema)
4. We're targeting modern browsers only (no IE11)
→ Correct me now or I'll proceed with these.
```

Don't silently fill in ambiguous requirements. The spec's entire purpose is to surface misunderstandings *before* code gets written — assumptions are the most dangerous form of misunderstanding.

**Map existing code first.** If `.codegraph/` exists, run `codegraph context "<feature>" --no-code` to find entry points and related symbols before writing the spec. This prevents speccing features that conflict with existing architecture.

**Map business domain.** Run the `understand-domain` skill to map code structures to business processes — essential for writing a PRD that reflects real-world workflows, not just technical components.

**Write a PRD document covering these product areas:**

1. **Problem** — What is broken? What is the pain point?
2. **Goals & Non-Goals** — What outcomes must we achieve? What is explicitly out of scope?
3. **User Stories** — "As a [user], I want [goal], so that [benefit]."
4. **Success Criteria** — Measurable metrics for completion.

**PRD.md template (save to `$TGD_DIR/<feature-name>/PRD.md`):**

```markdown
# PRD: [Feature Name]

| Metadata       | Details                           |
|----------------|-----------------------------------|
| **Status**     | Draft / Ready for Dev             |
| **Author**     | Product Manager                   |
| **Date**       | YYYY-MM-DD                        |

## 1. Executive Summary
[Why are we doing this? Business value? Expected impact?]

## 2. Problem Statement
- **Current state:** [What is happening now?]
- **Pain point:** [What is the problem?]
- **Impact:** [How does this affect users/business?]

## 3. Goals & Non-Goals
- **Goals:** (outcomes, not features — what changes for the user?)
  - [e.g., "Users can recover access without an email round-trip" — not "Add SMS OTP"]
- **Non-Goals:**
  - [What is explicitly out of scope for this iteration?]
  - [Things we considered but chose not to do — and why]

## 4. Target Audience
- **Primary:** [Who is this for?]
- **Secondary:** [Who else benefits?]
- **User scale:** [Expected MAU/DAU]

## 5. User Stories
| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|---------------------|
| US-01 | As a [role], I want [goal], so [benefit] | P0 | [Specific criteria] |

## 6. Success Metrics (KPIs)
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| [Metric 1] | [Target] | [How to measure] |

## 7. Scope
(deliverables, not outcomes — what gets built and when)
- **Phase 1:** [Must haves]
- **Phase 2:** [Nice to haves]
- **Phase 3:** [Future]
- **Out of Scope:** See §3 Non-Goals

## 8. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | High/Med/Low | [Strategy] |

## 9. Competitive Analysis (if applicable)
| Feature | Our Product | Competitor A | Competitor B |
|---------|-------------|--------------|--------------|
| [Feature] | ✅/❌/Phase N | ✅/❌ | ✅/❌ |

## 10. Stakeholder Alignment (if applicable)
- **PM:** [Sign-off on scope]
- **Design:** [Sign-off on UX flow]
- **Engineering:** [Sign-off on feasibility]
- **Security:** [Sign-off on security requirements]

## 11. Timeline (if applicable)
| Phase | Duration | Milestone |
|-------|----------|-----------|
| Phase 1 | [X weeks] | [Milestone] |

## Sign-off
- [ ] **PM**: (pending)
```

The `## Sign-off` section is the PM's **final release approval** — `/tgd-release`'s hard gate greps this exact line and blocks until it reads `[x] **PM**: Approved`. It is NOT §10 Stakeholder Alignment (define-time scope alignment); it is the release-time go/no-go, same convention as TEST-REPORT.md (QA) and REVIEW.md (QA + DEV).

Sections 1–8 are always required. **9 Competitive Analysis**, **10 Stakeholder Alignment**, and **11 Timeline** are marked *(if applicable)* — a solo or small feature may omit them. `/tgd-define`'s gate (`check-doc-sections.py`) enforces exactly this: the always-required sections must be present, the *(if applicable)* ones are not forced. To make another section optional, mark it *(if applicable)* here — the gate reads this template as its single source, so nothing else needs to change.

**§6 Success Metrics — filling rules (enforced by `/tgd-define`'s gate):**

A metric whose number has no named source is not a metric. Every row's **Measurement Method** must be exactly one of:

1. **A concrete query in an existing tool** — e.g. "GA4 funnel report `sign_up`", "Grafana dashboard `api-latency`, p95 panel". "Check analytics" or "look at usage" is a placeholder, not a source.
2. **A named tracking event that does not exist yet** — write the event name (e.g. `sign_up_completed`). `/tgd-plan` will register it in `$TGD_DIR/TRACKING-PLAN.md` and create an instrumentation task with its own acceptance criteria (see `tgd-planning-and-task-breakdown`).
3. **`N/A — no user-measurable outcome`** — legitimate for refactors, internal tooling, migrations. Requires a named PM sign-off line directly under the table (`Approved N/A — PM, YYYY-MM-DD`). An N/A without sign-off fails the define gate; a fabricated metric ("deploy success rate 100%") is worse than an honest N/A.

At `/tgd-release`, the §6 table becomes `$TGD_DIR/<feature-name>/METRICS.md` — a handoff sheet whose Actual column is filled by whoever owns the data (PM, analyst), on their schedule, in their rituals. tGD's responsibility ends at making that sheet accurate and cheap to fill.

**SPEC.md template (save to `$TGD_DIR/<feature-name>/SPEC.md`):**

```markdown
# SPEC: [Feature Name]

## Feature Type
- [ ] **Backend** (API / CLI / Service)
- [ ] **Frontend** (UI / Web / Mobile)
- [ ] **Full-stack** (Both)

### UI Requirements (if Frontend or Full-stack)
- **Design Source**: [Figma URL / Screenshot / PDF / None]
- **Pages/Screens**: [List of screens needed]
- **Key Components**: [Component names]
- **Responsive**: [Mobile-first / Desktop-first / Both]

## Tech Stack
[Framework, language, key dependencies with versions]

## Architecture / Data Models
[Data models, endpoints, key algorithms, schema definitions]

## Project Structure
[Directory layout with descriptions]

## API Contract
[Input/Output definitions for key endpoints]

## Testing Strategy
[Framework, test locations, coverage requirements]

## Boundaries
- Always: [...]
- Ask first: [...]
- Never: [...]
```

### Phase 1.5: UI Design Gate (MANDATORY USER PROMPT)

After writing SPEC.md, you MUST stop and ask the user via **Selection Protocol**:
"**Does this feature have a UI component requiring DESIGN.md?**"
**Format:** "1. Yes (Generate design) 2. No (Backend only)"
**Do NOT skip this step. You cannot self-determine UI vs Backend — the user decides.**

**If user confirms YES:**
1. **Check existing design** in SPEC.md:
   - If `[Figma URL]` → fetch the URL with your platform's web-fetch capability and extract the component structure; if the platform cannot render it, ask the user for a screenshot export → skip to step 3
   - If `[Screenshot/PDF]` → read the image with vision and extract the UI elements → skip to step 3
   - If `[None]` → proceed to step 2

2. **Generate design mockups** (via the `tgd-sketch` skill):
   - Read the SPEC.md for feature requirements
   - Generate 3 variants (Conservative / Strong-fit / Divergent) as self-contained HTML files
   - Save to `$TGD_DIR/<feature-name>/prototype/` — the same directory `/tgd-define`'s verification gate checks
   - Present the 3 variants to the user with a comparison table
   - **STOP. Ask user to pick a direction** (or request a hybrid)

3. **Write DESIGN.md** based on chosen design:
   - Extract from chosen variant (or existing design if step 1 was used)
   - Apply anti-slop rules from the template below
   - Save to `$TGD_DIR/<feature-name>/DESIGN.md`

4. **Confirm with user:**
   - Present DESIGN.md summary: Visual Direction, Font choices, Color palette, Spacing
   - **STOP. Ask user:** "DESIGN.md confirmed? Ready to proceed to PLAN?"
   - If not satisfied → modify DESIGN.md → re-confirm

**If user confirms NO:**
- Skip DESIGN.md entirely and proceed to PLAN.

**DESIGN.md template (save to `$TGD_DIR/<feature-name>/DESIGN.md`):**
```markdown
# DESIGN: [Feature Name]

## Source
- **Type**: [Figma / Mockup / Screenshot]
- **URL/Path**: [link or file path]
- **Variant**: [Conservative / Strong-fit / Divergent]

## Visual Direction
- **Reference**: [Product name, e.g. Linear / Stripe / Vercel]
- **Vibe**: [e.g. "ultra-minimal dark, precise, purple accent"]
- **Anti-patterns** (MUST NOT):
  - Fonts: Inter, Roboto, Arial, Open Sans, system defaults
  - Colors: pure black (#000), pure white (#fff), cyan-on-dark, purple-to-blue gradients, neon accents
  - Layout: everything in cards, cards inside cards, identical card grids, center everything
  - Visual: glassmorphism, gradient text, rounded rectangles with thick colored border on one side
  - Motion: bounce/elastic easing, animate layout properties (width/height/padding)
  - Content: lorem ipsum, fake metrics, placeholder testimonials, decorative SVG illustrations

## Component Tree
- Page
  - Header
  - LoginForm
    - InputField × 2
    - SubmitButton
  - Footer

## Design Tokens
| Token | Value | Notes |
|-------|-------|-------|
| color-bg | #0a0a0a | tinted, not pure black |
| color-surface | #111111 | |
| color-text | #e5e5e5 | |
| color-text-muted | #737373 | |
| color-accent | #3b82f6 | one primary accent only |
| color-success | #22c55e | |
| color-danger | #ef4444 | |
| color-border | #262626 | |
| font-heading | [Choose: Space Grotesk / DM Sans / Geist / etc.] | NOT Inter/Roboto |
| font-body | [Choose: DM Sans / Source Sans 3 / Geist / etc.] | NOT Inter/Roboto |
| font-mono | JetBrains Mono | code only, not everywhere |
| radius-sm | 4px | |
| radius-md | 8px | |
| radius-lg | 12px | |

## Typography Scale
| Level | Size | Weight | Letter-spacing | Usage |
|-------|------|--------|----------------|-------|
| h1 | clamp(36px, 5vw, 64px) | 800 | -0.03em | Page title (one per page) |
| h2 | clamp(24px, 3vw, 40px) | 700 | -0.02em | Section title |
| h3 | 20px | 600 | -0.01em | Subsection |
| body | 16px | 400 | 0 | Default text |
| small | 13px | 400 | 0 | Helper / secondary |
| code | 14px | 400 | 0 | Monospace, inline |

## Spacing System
| Token | Value | Usage |
|-------|-------|-------|
| space-xs | 4px | Tight gaps |
| space-sm | 8px | Inner padding |
| space-md | 16px | Card padding, gaps |
| space-lg | 24px | Section gaps |
| space-xl | 32px | Section padding |
| space-2xl | 48px | Major sections |
| space-3xl | 64px | Hero / page margins |

## Responsive
| Breakpoint | Layout | Notes |
|------------|--------|-------|
| mobile (<768px) | Stack vertically | Touch targets ≥ 44px |
| tablet (768-1024px) | 2-column where appropriate | |
| desktop (≥1024px) | Full layout | |

## Interactions
- Submit button: idle → loading → success/error
- Hover: subtle lift + shadow (use transform, not layout properties)
- Focus: visible focus ring (2px accent, 2px offset)
- Transitions: 0.2s ease for micro-interactions, 0.3s ease for state changes

## States
| State | Treatment |
|-------|-----------|
| Loading | Skeleton placeholders, NOT spinners for content |
| Empty | Icon + message + CTA button |
| Error | Message + retry button, NOT just red text |
| Success | Brief confirmation, auto-dismiss |

## Accessibility
- Contrast ratio ≥ 4.5:1 for normal text, ≥ 3:1 for large text
- All interactive elements keyboard navigable (Tab/Enter/Space)
- Visible focus indicators on all focusable elements
- `prefers-reduced-motion` disables non-essential animations
- `aria-label` on icon-only buttons
- Semantic HTML: `<button>` not `<div onClick>`, `<nav>`, `<main>`, `<section>`
- Color is NOT the sole indicator of state (always pair with text/icon)
```

**Reframe instructions as success criteria.** When receiving vague requirements, translate them into concrete conditions:

```
REQUIREMENT: "Make the dashboard faster"

REFRAMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

This lets you loop, retry, and problem-solve toward a clear goal rather than guessing what "faster" means.

### Phases 2–4: Plan, Tasks, Implement — owned by later lifecycle stages

This skill's deliverable ends at the validated PRD + SPEC (+ DESIGN if UI). The
remaining phases belong to their own commands and skills — do NOT plan, break
down tasks, or implement from here, and do NOT use ad-hoc task formats:

- **Plan + Tasks** → `/tgd-plan` running `tgd-planning-and-task-breakdown`.
  That skill owns the TASKS.md template — including the `AC-<task>.<n>`
  criterion ids and `[R]`/`Test:` fields that `/tgd-verify`'s `ac-trace.py`
  gate enforces. A task list written from memory here will fail that gate.
- **Implement** → `/tgd-develop` running `tgd-incremental-implementation` or
  `tgd-subagent-driven-development`, with `tgd-test-driven-development` and
  `tgd-context-engineering`.

## Keeping the Spec Alive

The spec is a living document, not a one-time artifact:

- **Update when decisions change** — If you discover the data model needs to change, update the spec first, then implement.
- **Update when scope changes** — Features added or cut should be reflected in the spec.
- **Commit the spec** — The spec belongs in version control alongside the code.
- **Reference the spec in PRs** — Link back to the spec section that each PR implements.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need *long* specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is in forcing clarity *before* code. |
| "The spec will slow us down" | A 15-minute spec prevents hours of rework. Waterfall in 15 minutes beats debugging in 15 hours. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas
- [ ] The human has reviewed and approved the spec
- [ ] Success criteria are specific and testable
- [ ] Boundaries (Always/Ask First/Never) are defined
- [ ] The spec is saved to `$TGD_DIR/<feature-name>/SPEC.md`
- [ ] No feature branch was created or checked out (that happens in `/tgd-develop`'s worktree step)
- [ ] If UI feature: 3 design variants generated, user picked a direction
- [ ] If UI feature: `$TGD_DIR/<feature-name>/DESIGN.md` exists with all required sections
- [ ] If UI feature: user confirmed DESIGN.md before proceeding to PLAN
