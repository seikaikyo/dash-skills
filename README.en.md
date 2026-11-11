# Dash Skills

**Claude Code Skills Collection**

**English** | [日本語](./README.ja.md) | [正體中文](./README.md)

## Overview

Centralized management of Claude Code Skills -- custom tech-stack standards + curated external skills, with daily auto-sync.

## Included Skills

> 20 custom (`skills/`) + 25 external (`external/`). External skills auto-sync daily from upstream.

### Custom (`skills/`)

| Skill | Description |
|-------|-------------|
| **angular-primeng** | Angular 21 + PrimeNG enterprise standards (MES / ERP / admin) |
| **fastapi-patterns** | FastAPI + SQLModel + Neon backend standards |
| **openspec** | Spec-driven development (SDD) workflow |
| **security-reviewer** | Vulnerability detection and fix, mapped to OWASP Top 10:2025, Agentic Applications 2026 and GenAI LLM Top 10 2026 |
| **build-error-resolver** | Build and TypeScript error quick-fix |
| **refactor-cleaner** | Dead code cleanup and refactor consolidation |
| **architecture-audit** | Audit docs vs actual code structure (CLAUDE.md drift) |
| **cis-design-system** | CIS corporate identity design system |
| **quality-gate** | Frontend quality gate (SEO / a11y / perf / UI-UX) |
| **doubt-driven-development** | Fresh-context adversarial review for non-trivial decisions (adapted from tGD, Apache-2.0) |
| **interview-me** | Intent-extraction interview for underspecified asks (adapted from tGD, Apache-2.0) |
| **sketch** | Throwaway HTML mockups, 2-3 design-stance variants (adapted from tGD, Apache-2.0) |
| **security-scan** | Three-layer external scan (deps / secrets / SAST) mapped to OWASP Top 10:2025 |
| **security-radar** | Security package radar: daily automated scan curating effective / popular / self-secure security tools, with coverage matrices for OWASP Top 10:2025, Agentic Applications 2026 and LLM Top 10 2026 |
| **humanizer-zh-tw** | Rewrite tool to strip Chinese AI writing patterns (enforced) |
| **humanizer-en** | Rewrite tool to strip English AI writing patterns |
| **interface-design** | Craft-first design foundation and audit for dashboards, admin panels and tools |
| **webapp-uat** | Screen-by-screen UAT of deployed apps (agent-browser, 3-size RWD, trilingual i18n, console/network, Sentry) |
| **ui-ux-pro-max** | 50+ UI styles / 161 palettes / 57 font pairings (vendored from nextlevelbuilder/ui-ux-pro-max-skill, MIT) |
| **web-design-guidelines** | Front-end UI code review against a fixed rule set, reported as file:line (a11y / keyboard / forms / motion / perf) |

### Development & Deployment

| Skill | Description | Source |
|-------|-------------|--------|
| **react-best-practices** | React / Next.js performance optimization | vercel-labs/agent-skills |
| **vercel-optimize** | Vercel cost and performance audit (driven by production metrics) | vercel-labs/agent-skills |
| **deploy-to-vercel** | Deploy apps to Vercel | vercel-labs/agent-skills |
| **agent-browser** | Browser automation CLI (200+ commands) | vercel-labs/agent-browser |
| **mcp-builder** | Build high-quality MCP servers | anthropics/skills |
| **skill-creator** | Create / improve / evaluate skills | anthropics/skills |
| **claude-api** | Claude API usage guide | anthropics/skills |

### UI/UX & Design

| Skill | Description | Source |
|-------|-------------|--------|
| **frontend-design** | Anti-generic-AI frontend design | anthropics/skills |
| **canvas-design** | PNG / PDF visual art via design philosophy | anthropics/skills |
| **brand-guidelines** | Apply Anthropic brand colors and typography | anthropics/skills |
| **theme-factory** | Style artifacts with themes (10 presets) | anthropics/skills |
| **web-artifacts-builder** | Build multi-component claude.ai HTML artifacts | anthropics/skills |
| **algorithmic-art** | Algorithmic art with p5.js | anthropics/skills |

### Testing

| Skill | Description | Source |
|-------|-------------|--------|
| **webapp-testing** | Test local web apps with Playwright | anthropics/skills |

### Security / Compliance

| Skill | Description | Source |
|-------|-------------|--------|
| **trailofbits-security** | Security analysis plugins (CodeQL / Semgrep) | trailofbits/skills |
| **sentry-security-review** | Sentry-convention commits + security review | getsentry/skills |
| **cloudflare-security-audit** | Multi-agent orchestrated penetration audit (recon / attack classes / validated reporting) | cloudflare/security-audit-skill |

### Document Processing

| Skill | Description | Source |
|-------|-------------|--------|
| **docx** | Create / read / edit Word docs | anthropics/skills |
| **pdf** | Process PDFs (read / merge / extract) | anthropics/skills |
| **pptx** | Create / edit presentations | anthropics/skills |
| **xlsx** | Create / edit spreadsheets | anthropics/skills |

### Writing & Content

| Skill | Description | Source |
|-------|-------------|--------|
| **doc-coauthoring** | Structured doc co-authoring workflow | anthropics/skills |
| **internal-comms** | Internal comms (status reports / leadership updates) | anthropics/skills |

### Video / Animation

| Skill | Description | Source |
|-------|-------------|--------|
| **slack-gif-creator** | Slack-optimized animated GIFs | anthropics/skills |

### Database

| Skill | Description | Source |
|-------|-------------|--------|
| **neon-skills** | Neon serverless driver config (6 sub-skills) | neondatabase/ai-rules |

## pi.dev Config (`pi-agent/`)

Beyond Claude Code skills, this repo also holds personal pi.dev coding agent config that takes effect on read.

| File | Purpose |
|------|---------|
| `AGENTS.md` | Work style and engineering discipline |
| `APPEND_SYSTEM.md` | Core behavior constraints (secrecy boundary / confirm-before-outbound / honesty / brevity) |
| `extensions/guardrails.ts` | Dangerous git / sensitive-file / emoji guards |
| `settings.fragment.json` | Points to skills and extensions |

See [`pi-agent/README.md`](./pi-agent/README.md) for install and placement.

## Installation

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

## Auto-Sync

Runs daily at 06:00 in the background via launchd, logging to `~/Library/Logs/dash-skills-auto-update.log`:

```bash
cp scripts/launchd/com.dash.skills-auto-update.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dash.skills-auto-update.plist
```

Add to `~/.zshrc` to catch up when the day's run has not finished (returns immediately):

```bash
[ "$(cat ~/Documents/github/dash-skills/.last-update 2>/dev/null)" = "$(date +%Y-%m-%d)" ] || launchctl kickstart gui/$(id -u)/com.dash.skills-auto-update 2>/dev/null
```

Daily auto: update external skills, auto commit + push. The agent-browser CLI is not upgraded automatically: review the release, then run `npm install -g agent-browser@<version>` by hand.

## License

- Custom Skills: MIT License
- External Skills: per source license

## Author

SeiKai Kyo

## Sources

External skills come from open-source communities, licensed per source. Main sources:

- [Anthropic](https://github.com/anthropics/skills) -- official skills (document processing / design / mcp-builder, etc.)
- [Vercel Labs](https://github.com/vercel-labs) -- react-best-practices, agent-browser, deploy-to-vercel, vercel-optimize
- [Neon](https://github.com/neondatabase) -- neon-skills
- [Trail of Bits](https://github.com/trailofbits) -- security plugins
- [Cloudflare](https://github.com/cloudflare/security-audit-skill) -- cloudflare-security-audit
- [Sentry](https://github.com/getsentry/skills) -- sentry-security-review
- Custom skills adapted or vendored from: nextlevelbuilder/ui-ux-pro-max-skill (MIT), everything-claude-code (MIT), tGD (Apache-2.0)
