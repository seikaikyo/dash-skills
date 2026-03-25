# skill-extractor

Extract reusable skills from work sessions. Manual invocation only - no hooks, no noise.

## Usage

```
/skill-extractor [--project] [context hint]
```

Invoke after solving a non-obvious problem to capture the knowledge as a reusable skill.

**Examples:**
```
/skill-extractor                           # Extract from current session
/skill-extractor --project                 # Save to project instead of user level
/skill-extractor the cyclic data DoS fix  # Hint to focus extraction
```

## What It Does

1. Analyzes your conversation for extractable knowledge
2. Presents a quality checklist for confirmation
3. Optionally researches best practices (web search, Context7)
4. Generates a skill following repository standards
5. Validates structure before saving
6. Saves to `~/.claude/skills/` or `.claude/skills/`

## Quality Gates

Before extraction, you confirm:
- Reusable (helps future tasks)
- Non-trivial (required discovery)
- Verified (solution worked)
- Specific triggers (exact errors/scenarios)
- Explains WHY (not just steps)

## Installation

```
/plugin install trailofbits/skills-curated/plugins/skill-extractor
```
