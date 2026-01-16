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

#### Vercel Labs

| Skill | Description | Rules |
|-------|-------------|-------|
| **react-best-practices** | React/Next.js performance guide | 40+ |
| **agent-browser** | Browser automation CLI | 200+ commands |
| **web-design-guidelines** | UI review rules (a11y, UX, perf) | 80+ |

#### Neon Database (`neon-skills/`)

| Skill | Description |
|-------|-------------|
| **neon-drizzle** | Drizzle ORM integration |
| **neon-serverless** | Serverless connection setup |
| **neon-toolkit** | Ephemeral DB management (testing/CI) |
| **neon-auth** | Authentication integration |
| **neon-js** | JS SDK setup |
| **add-neon-docs** | Documentation installation |

## Installation

### Method 1: Install Script (Recommended)

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### Method 2: Manual Copy

```bash
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### Method 3: Symlink (For Development)

```bash
./scripts/link.sh
```

## Usage

After installation, trigger skills in Claude Code:

```bash
# Custom Skills
/angular-primeng       # Angular + PrimeNG guidelines
/vue-daisyui           # Vue + DaisyUI prototyping
/fastapi-patterns      # FastAPI backend guidelines

# Vercel Labs
/react-best-practices  # React/Next.js performance
/agent-browser         # Browser automation
/web-design-guidelines # UI review

# Neon Database
/neon-drizzle          # Drizzle ORM setup
/neon-serverless       # Serverless connection
/neon-auth             # Auth integration
```

## Directory Structure

```
dash-skills/
├── skills/                      # Custom Skills (3)
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
├── external/                    # External Skills (4 sources, 9 skills)
│   ├── react-best-practices/    # Vercel Labs
│   ├── agent-browser/           # Vercel Labs
│   ├── web-design-guidelines/   # Vercel Labs
│   └── neon-skills/             # Neon Database (6 skills)
│       ├── neon-drizzle/
│       ├── neon-serverless/
│       ├── neon-toolkit/
│       ├── neon-auth/
│       ├── neon-js/
│       └── add-neon-docs/
└── scripts/
    ├── install.sh
    ├── link.sh
    ├── sync.sh
    └── update-external.sh
```

## Syncing External Skills

```bash
# Update all
./scripts/update-external.sh

# List available
./scripts/update-external.sh --list

# Update specific
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh neon-skills
```

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

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser, web-design-guidelines
- [Neon Database](https://github.com/neondatabase) - neon-skills
