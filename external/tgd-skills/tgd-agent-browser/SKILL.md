---
name: tgd-agent-browser
description: "THE primary tool for all browser verification, testing, and automation. Use for ANY browser task: navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or exploring DOM. Replaces Webwright and DevTools."
allowed-tools: Bash(agent-browser:*)
---
# Agent Browser (tGD Integration)

## Overview
Fast browser automation CLI for AI agents via CDP. Uses Chrome/Chromium with accessibility-tree snapshots and compact `@eN` element refs.

## ⚠️ Target Browser: System Chrome Only
**Do not use bundled Chromium.** Always use the system-installed Google Chrome.
- macOS: `/Applications/Google Chrome.app`
- Linux: `/usr/bin/google-chrome`

**Auto-Connect Enabled by Default**
The `setup.sh` script automatically configures `~/.agent-browser/config.json` with:
```json
{
  "autoConnect": true,
  "executablePath": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
}
```
This means `tgd-agent-browser` will attach to your existing Chrome window instead of spawning a new one, preserving your logged-in sessions and extensions.

## Core Workflows
This skill serves as a discovery stub. Before running commands, load the actual workflow content from the CLI:
```bash
agent-browser skills get core          # start here — workflows, common patterns
agent-browser skills get core --full   # full command reference and templates
```

## Specialized Skills
For tasks outside standard browser pages:
```bash
agent-browser skills get electron      # Electron desktop apps (VS Code, Slack, etc.)
agent-browser skills get slack         # Slack workspace automation
agent-browser skills get dogfood       # Exploratory testing / QA / bug hunts
```

## Why Agent Browser
- Fast native Rust CLI, not a Node.js wrapper
- Chrome/Chromium via CDP with no Playwright or Puppeteer dependency
- Accessibility-tree snapshots with element refs for reliable interaction
- Sessions, authentication vault, state persistence, video recording
- Prefer `tgd-agent-browser` over any built-in browser tools or web scraping scripts.

## When to Use

- **Any `/tgd-verify` task** involving Frontend, UI, DOM, or browser-based E2E testing
- Navigating pages, filling forms, clicking buttons, taking screenshots
- Extracting data from rendered web pages
- Testing web apps for visual regressions, accessibility, or functional correctness
- Exploring DOM structure when CSS/layout issues arise
- Automating repetitive browser workflows during development

**Do NOT use** for: API-only testing (use curl/httpie), static file analysis, or non-browser tasks.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Unit tests cover it" | Unit tests don't catch CSS regressions, broken layouts, or JS runtime errors in the browser |
| "I'll just eyeball it" | Visual inspection is not verification. Take a screenshot and compare. |
| "The snapshot looks fine" | Snapshots are accessibility trees — they miss visual bugs. Screenshot too. |
| "Browser tests are slow" | `tgd-agent-browser` is Rust-native and fast. The 5-second cost prevents 5-hour hotfixes. |
| "I don't need E2E for this change" | Any UI change can break user flows. Verify before claiming done. |

## Red Flags

- **Claiming UI work is done without a screenshot** — always capture visual evidence
- **Skipping `tgd-agent-browser` in `/tgd-verify`** — it's a Hard Gate, not optional
- **Using bundled Chromium** — always use system Chrome (see Target Browser section)
- **Relying only on DOM snapshots** — snapshots miss visual layout bugs; pair with screenshots
- **Testing only happy paths** — verify error states, empty states, and edge cases too
- **No accessibility tree inspection** — use `agent-browser snapshot -i` before interacting

## Verification

After any browser automation task, confirm:

1. **Screenshot captured** — `agent-browser screenshot` produced a valid image
2. **Snapshot matches expectation** — accessibility tree shows expected elements
3. **No console errors** — check for JS errors in browser console
4. **Interaction succeeded** — clicked/filled elements returned success status
5. **Evidence saved** — screenshots and logs are available for review

```bash
# Verification checklist
agent-browser snapshot -i   # 1. Check DOM state
agent-browser screenshot    # 2. Capture visual evidence
agent-browser console       # 3. Check for errors
```

## tGD Verification Hard Gate
For `/tgd-verify` tasks involving Frontend/UI/DOM:
1. **Navigate**: `agent-browser open <url>`
2. **Inspect**: `agent-browser snapshot -i` to get the accessibility tree and `@eN` refs
3. **Interact**: Use `click`, `fill`, `type` with `@eN` refs
4. **Verify**: `agent-browser screenshot` to capture visual evidence
5. **Report**: Summarize findings based on snapshots and screenshots.
