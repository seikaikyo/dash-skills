# Dash Skills

**Custom Skills Collection for Claude Code**

English | [日本語](./README.ja.md) | [正體中文](./README.md)

## Overview

This repository centralizes custom Skills I've created for Claude Code. Skills are extensions for Claude Code that enable the AI assistant to provide more precise guidance in specific technical domains.

## Included Skills

| Skill | Description | Use Cases |
|-------|-------------|-----------|
| **angular-primeng** | Angular 21 + PrimeNG enterprise app development guidelines | MES, ERP, admin dashboards |
| **vue-daisyui** | Vue 3 CDN + DaisyUI rapid prototyping | POC, demos, internal tools |
| **fastapi-patterns** | FastAPI + SQLModel + Neon backend development | API services deployed on Render |

## Installation

### Method 1: Install Script (Recommended)

```bash
git clone https://github.com/anthropics/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### Method 2: Manual Copy

```bash
# Copy to Claude Code skills directory
cp -r skills/* ~/.claude/skills/
```

### Method 3: Symlink (For Development)

```bash
# Create symbolic links for easy sync
./scripts/link.sh
```

## Usage

After installation, trigger skills in Claude Code via commands:

```
/angular-primeng  - Load Angular + PrimeNG development guidelines
/vue-daisyui      - Load Vue + DaisyUI rapid prototyping guidelines
/fastapi-patterns - Load FastAPI backend development guidelines
```

Claude Code may also automatically suggest appropriate Skills based on your project type.

## Directory Structure

```
dash-skills/
├── README.md              # Documentation (Traditional Chinese)
├── README.en.md           # Documentation (English)
├── README.ja.md           # Documentation (Japanese)
├── scripts/
│   ├── install.sh         # Installation script
│   ├── link.sh            # Symlink script
│   └── sync.sh            # Sync script
└── skills/
    ├── angular-primeng/
    │   └── SKILL.md
    ├── vue-daisyui/
    │   └── SKILL.md
    └── fastapi-patterns/
        └── SKILL.md
```

## Skill Format

Each Skill contains a `SKILL.md` file with the following format:

```yaml
---
name: skill-name
description: Brief description of the skill
source: custom
updated: YYYY-MM-DD
---

# Skill Title

## Use Cases
...

## Core Principles
...
```

## Adding New Skills

1. Create a new directory under `skills/`
2. Create a `SKILL.md` file
3. Run `./scripts/sync.sh` to sync to `~/.claude/skills/`

## Syncing Updates

After updating skills in the repo:

```bash
git pull
./scripts/sync.sh
```

## Technology Stack Overview

These Skills are designed based on my technology stack:

| Layer | Technology |
|-------|------------|
| Frontend (Enterprise) | Angular 21 + PrimeNG |
| Frontend (Prototype) | Vue 3 CDN + DaisyUI |
| Backend | FastAPI + SQLModel |
| Database | Neon PostgreSQL |
| Frontend Deployment | Vercel |
| Backend Deployment | Render |

## License

MIT License

## Author

Dash
