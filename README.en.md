# Dash Skills

**Claude Code Skills Collection**

**English** | [日本語](./README.ja.md) | [正體中文](./README.md)

## Overview

Centralized management of Claude Code Skills -- custom tech-stack standards + curated external skills, with daily auto-sync.

## Included Skills

> 12 custom (`skills/`) + 48 external (`external/`). External skills auto-sync daily from upstream.

### Custom (`skills/`)

| Skill | Description |
|-------|-------------|
| **angular-primeng** | Angular 21 + PrimeNG enterprise standards (MES / ERP / admin) |
| **fastapi-patterns** | FastAPI + SQLModel + Neon backend standards |
| **openspec** | Spec-driven development (SDD) workflow |
| **security-reviewer** | Vulnerability detection and fix (OWASP Top 10) |
| **build-error-resolver** | Build and TypeScript error quick-fix |
| **refactor-cleaner** | Dead code cleanup and refactor consolidation |
| **architecture-audit** | Audit docs vs actual code structure (CLAUDE.md drift) |
| **cis-design-system** | CIS corporate identity design system |
| **quality-gate** | Frontend quality gate (SEO / a11y / perf / UI-UX) |
| **doubt-driven-development** | Fresh-context adversarial review for non-trivial decisions (adapted from tGD, Apache-2.0) |
| **interview-me** | Intent-extraction interview for underspecified asks (adapted from tGD, Apache-2.0) |
| **sketch** | Throwaway HTML mockups, 2-3 design-stance variants (adapted from tGD, Apache-2.0) |

### Development & Deployment

| Skill | Description | Source |
|-------|-------------|--------|
| **react-best-practices** | React / Next.js performance optimization | vercel-labs/agent-skills |
| **vercel-react-best-practices** | React / Next.js perf (TSX review) | vercel-labs/agent-skills |
| **vercel-python** | Python project Vercel deployment diagnosis/fix | vercel-labs/agent-skills |
| **vercel-cost-optimization** | Vercel billing analysis and cost optimization | vercel-labs/agent-skills |
| **deploy-to-vercel** | Deploy apps to Vercel | vercel-labs/agent-skills |
| **agent-browser** | Browser automation CLI (200+ commands) | vercel-labs/agent-browser |
| **mcp-builder** | Build high-quality MCP servers | anthropics/skills |
| **skill-creator** | Create / improve / evaluate skills | anthropics/skills |
| **claude-api** | Claude API usage guide | anthropics/skills |

### UI/UX & Design

| Skill | Description | Source |
|-------|-------------|--------|
| **frontend-design** | Anti-generic-AI frontend design | anthropics/skills |
| **interface-design** | Design memory system for component consistency | Dammyjay93/interface-design |
| **ui-ux-pro-max** | 50+ UI styles / 161 palettes / 57 font pairings | nextlevelbuilder/ui-ux-pro-max-skill |
| **bencium-marketplace** | UX audit + typography + innovative UX | bencium/bencium-marketplace |
| **web-design-guidelines** | UI code review (a11y / UX / perf) | vercel-labs/agent-skills |
| **canvas-design** | PNG / PDF visual art via design philosophy | anthropics/skills |
| **brand-guidelines** | Apply Anthropic brand colors and typography | anthropics/skills |
| **theme-factory** | Style artifacts with themes (10 presets) | anthropics/skills |
| **web-artifacts-builder** | Build multi-component claude.ai HTML artifacts | anthropics/skills |
| **algorithmic-art** | Algorithmic art with p5.js | anthropics/skills |

### Accessibility

| Skill | Description | Source |
|-------|-------------|--------|
| **accessibility-agents** | WCAG AA enforcement (80 agents + 25 commands) | Community-Access/accessibility-agents |

### Testing

| Skill | Description | Source |
|-------|-------------|--------|
| **webapp-testing** | Test local web apps with Playwright | anthropics/skills |
| **webapp-uat** | Full browser UAT (console / network / a11y / i18n) | tsilverberg/webapp-uat |

### Security / Compliance

| Skill | Description | Source |
|-------|-------------|--------|
| **security-audit** | White/gray-box security audit (ISO 27001 mapped) | afiqiqmal/claude-security-audit |
| **security-skills** | Security automation skill marketplace | eth0izzle/security-skills |
| **claude-code-owasp** | OWASP Top 10 code security review | agamm/claude-code-owasp |
| **ot-security-mcp** | IEC 62443 / NIST 800-82 OT security MCP | Ansvar-Systems/ot-security-mcp |
| **trailofbits-security** | Security analysis plugins (CodeQL / Semgrep) | trailofbits/skills |
| **trailofbits-skills-curated** | Trail of Bits vetted plugins | trailofbits/skills-curated |
| **sentry-security-review** | Sentry-convention commits + security review | getsentry/skills |
| **anthropic-cybersecurity-skills** | Cybersecurity skill collection | mukul975/Anthropic-Cybersecurity-Skills |

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
| **humanizer-zh-tw** | Remove Chinese AI writing patterns (enforced) | kevintsai1202/Humanizer-zh-TW |
| **humanizer-en** | Remove English AI writing patterns | blader/humanizer |
| **content-research-writer** | Research + citation-assisted content writing | ComposioHQ/awesome-claude-skills |
| **creative-writing-skills** | Fictional world / character wiki writing | haowjy/creative-writing-skills |
| **paper-writer-skill** | Medical / scientific paper writing workflow | kgraph57/paper-writer-skill |
| **storytelling** | Narrative arcs connecting product value to pain | gtmagents/gtm-agents |
| **doc-coauthoring** | Structured doc co-authoring workflow | anthropics/skills |
| **internal-comms** | Internal comms (status reports / leadership updates) | anthropics/skills |

### Video / Animation

| Skill | Description | Source |
|-------|-------------|--------|
| **remotion-video-skill** | Programmatic video generation with Remotion | wshuyi/remotion-video-skill |
| **slack-gif-creator** | Slack-optimized animated GIFs | anthropics/skills |

### Database

| Skill | Description | Source |
|-------|-------------|--------|
| **neon-skills** | Neon serverless driver config (6 sub-skills) | neondatabase/ai-rules |

### Removed

| Skill | Reason |
|-------|--------|
| ~~cisco-skill-scanner~~ | No longer synced |
| ~~neon-ai-rules~~ | Merged into neon-skills |
| ~~ux-designer~~ | bencium/design-skill repo gone |
| ~~ui-agents~~ | JakobStadler/claude-code-ui-agents repo gone |
| ~~claude-designer~~ | joeseesun/claude-designer-skill repo gone |

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

Add to `~/.zshrc`:

```bash
source ~/Documents/github/dash-skills/scripts/auto-update.sh
```

Daily auto: update SKILL.md files, check agent-browser CLI version, auto commit + push.

## Changelog

### 2026-06-09

- README full sync: skill list expanded from 22 to 54 (9 custom + 45 external), upstream source noted per external skill
- Removed defunct entries: cisco-skill-scanner, neon-ai-rules (merged into neon-skills)
- Added `pi-agent/`: personal pi.dev coding agent config (AGENTS.md / APPEND_SYSTEM.md / guardrails extension / settings fragment)

### 2026-03-14

- Added 5 security skills (security-audit, ot-security-mcp, trailofbits, sentry, cisco)
- Added 3 UI/UX skills (frontend-design, accessibility-agents, bencium-marketplace)
- Removed defunct repos (ux-designer, ui-agents, claude-designer)
- Fixed update-external.sh crash on failed git clone
- Added agent-browser CLI npm auto-update

### 2026-01-16

- Initial release

## License

- Custom Skills: MIT License
- External Skills: per source license

## Author

SeiKai Kyo

## Sources

External skills come from open-source communities, licensed per source. Main sources:

- [Anthropic](https://github.com/anthropics/skills) -- official skills (document processing / design / mcp-builder, etc.)
- [Vercel Labs](https://github.com/vercel-labs) -- react-best-practices, agent-browser, web-design-guidelines, vercel series
- [Neon](https://github.com/neondatabase) -- neon-skills
- [Trail of Bits](https://github.com/trailofbits) -- security plugins
- plus Dammyjay93, nextlevelbuilder, bencium, Community-Access, kevintsai1202, blader, haowjy, kgraph57, ComposioHQ, gtmagents, agamm, mukul975, eth0izzle, afiqiqmal, getsentry, Ansvar-Systems, tsilverberg, wshuyi, and others
