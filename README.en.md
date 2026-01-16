# Dash Skills

**Custom Skills Collection for Claude Code**

English | [日本語](./README.ja.md) | [正體中文](./README.md)

## Overview

This repository centralizes Skills for Claude Code. It includes custom-built technical stack guidelines and curated external Skills.

## Included Skills

### Custom Skills (`skills/`)

| Skill | Description | Use Cases |
|-------|-------------|-----------|
| **angular-primeng** | Angular 21 + PrimeNG enterprise app guidelines | MES, ERP, admin dashboards |
| **vue-daisyui** | Vue 3 CDN + DaisyUI rapid prototyping | POC, demos, internal tools |
| **fastapi-patterns** | FastAPI + SQLModel + Neon backend development | API services on Render |

### External Skills (`external/`)

| Skill | Source | Description |
|-------|--------|-------------|
| **react-best-practices** | [Vercel Labs](https://github.com/vercel-labs/agent-skills) | React/Next.js performance guide (40+ rules) |
| **agent-browser** | [Vercel Labs](https://github.com/vercel-labs/agent-browser) | Browser automation (200+ commands) |

## Installation

### Method 1: Install Script (Recommended)

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### Method 2: Manual Copy

```bash
# Copy to Claude Code skills directory
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### Method 3: Symlink (For Development)

```bash
# Create symbolic links for easy sync
./scripts/link.sh
```

## Usage

After installation, trigger skills in Claude Code via commands:

```
# Custom Skills
/angular-primeng  - Load Angular + PrimeNG guidelines
/vue-daisyui      - Load Vue + DaisyUI prototyping guidelines
/fastapi-patterns - Load FastAPI backend guidelines

# External Skills
/react-best-practices - Load React/Next.js performance guide
/agent-browser        - Load browser automation tools
```

## Directory Structure

```
dash-skills/
├── README.md              # Documentation (Traditional Chinese)
├── README.en.md           # Documentation (English)
├── README.ja.md           # Documentation (Japanese)
├── scripts/
│   ├── install.sh         # Installation script
│   ├── link.sh            # Symlink script
│   ├── sync.sh            # Sync script (custom)
│   └── update-external.sh # Sync script (external)
├── skills/                # Custom Skills
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
└── external/              # External Skills
    ├── react-best-practices/
    └── agent-browser/
```

## Syncing External Skills

External Skills can be updated from official sources:

```bash
# Update all external skills
./scripts/update-external.sh

# Update specific skill
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh agent-browser
```

## Skill Format

Each Skill contains a `SKILL.md` file:

```yaml
---
name: skill-name
description: Brief description
source: custom | URL
updated: YYYY-MM-DD
---

# Skill Title
...
```

## Adding Skills

### Adding Custom Skills

1. Create a new directory under `skills/`
2. Create a `SKILL.md` file
3. Run `./scripts/sync.sh` to sync to `~/.claude/skills/`

### Adding External Skills

1. Create a new directory under `external/`
2. Copy skill files
3. Add sync function in `scripts/update-external.sh`
4. Run install script

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend (Enterprise) | Angular 21 + PrimeNG |
| Frontend (Prototype) | Vue 3 CDN + DaisyUI |
| Backend | FastAPI + SQLModel |
| Database | Neon PostgreSQL |
| Frontend Deployment | Vercel |
| Backend Deployment | Render |

## License

- Custom Skills: MIT License
- External Skills: Per source license

## Author

Dash

## Acknowledgments

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser
