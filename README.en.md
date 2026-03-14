# Dash Skills

**Claude Code Skills Collection**

**English** | [日本語](./README.ja.md) | [正體中文](./README.md)

## Overview

Centralized management of Claude Code Skills -- custom tech-stack standards + curated external skills, with daily auto-sync.

## Included Skills

### Custom (`skills/`)

| Skill | Description | Use Case |
|-------|-------------|----------|
| **angular-primeng** | Angular 21 + PrimeNG enterprise standards | MES, ERP, admin panels |
| **fastapi-patterns** | FastAPI + SQLModel + Neon backend | Render-deployed APIs |
| **openspec** | Spec-driven development (SDD) workflow | Feature planning, change management |
| **security-reviewer** | OWASP Top 10 vulnerability detection | Auth, user input, APIs |
| **build-error-resolver** | Build/TypeScript error quick-fix | Build failures, type errors |
| **refactor-cleaner** | Dead code detection and cleanup | Code health, dependency cleanup |

### External (`external/`)

#### Vercel Labs
| Skill | Description |
|-------|-------------|
| **react-best-practices** | React/Next.js performance optimization (40+ rules) |
| **agent-browser** | Browser automation (200+ commands) + CLI auto-update |
| **web-design-guidelines** | UI review (a11y, UX, performance, 80+ rules) |

#### UI/UX Design
| Skill | Description | Source |
|-------|-------------|--------|
| **frontend-design** | Anti-generic AI aesthetic frontend design | Anthropic Official |
| **interface-design** | Design memory system for consistent components | Dammyjay93 |
| **ui-ux-pro-max** | 67 UI styles, 96 color palettes, 56 font pairings | nextlevelbuilder |
| **bencium-marketplace** | UX audit + typography + innovative UX | bencium |

#### Accessibility
| Skill | Description | Source |
|-------|-------------|--------|
| **accessibility-agents** | 57 WCAG 2.2 AA audit agents | Community-Access |

#### Security / Compliance
| Skill | Description | Source |
|-------|-------------|--------|
| **security-audit** | ISO 27001:2022 mapped, 850+ checks | afiqiqmal |
| **ot-security-mcp** | IEC 62443 / NIST 800-82 OT Security MCP | Ansvar-Systems |
| **trailofbits-security** | 35 plugins (CodeQL/Semgrep/variant analysis) | Trail of Bits |
| **sentry-security-review** | Low false-positive security code review | Sentry |
| **cisco-skill-scanner** | Skill supply-chain security scanner | Cisco AI Defense |

#### Writing
| Skill | Description | Source |
|-------|-------------|--------|
| **humanizer-zh-tw** | Remove AI writing patterns (enforced) | kevintsai1202 |

#### Neon Database
| Skill | Description |
|-------|-------------|
| **neon-ai-rules** | Complete Neon rules + .mdc files |
| **neon-skills/** | 6 skills (drizzle, serverless, toolkit, auth, js, docs) |

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
