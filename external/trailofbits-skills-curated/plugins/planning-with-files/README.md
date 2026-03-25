# Planning with Files

File-based planning with persistent markdown files for complex multi-step tasks.

## Installation

```
/plugin install trailofbits/skills-curated/plugins/planning-with-files
```

## Usage

### /plan

Creates three planning files in your project root:

- `task_plan.md` -- phases, progress, decisions, error log
- `findings.md` -- research discoveries and technical decisions
- `progress.md` -- session log and test results

### /status

Shows a compact summary of your current task phases and progress.

## How It Works

The core idea: your context window is volatile RAM, the filesystem is persistent disk. Writing goals, decisions, and findings to markdown files prevents context drift during long tasks.

The key pattern is **read-before-decide**: re-reading `task_plan.md` before major decisions pushes goals back into the attention window, counteracting the "lost in the middle" effect that occurs after many tool calls.

The plugin includes a Stop hook that reports phase completion status when a session ends.

## What's Included

| Component | Purpose |
|-----------|---------|
| Skill | Core planning methodology and rules |
| `/plan` command | Create planning files from templates |
| `/status` command | Show phase summary |
| Stop hook | Report completion status on session end |

## Credits

Based on [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files), which implements context engineering principles from [Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus). Restructured as a curated Claude Code plugin with multi-IDE bloat removed, expensive hooks dropped, and templates cleaned up.
