---
name: tgd-wiki-generation
description: Compiles CodeGraph + Understand-Anything outputs into a self-contained single-file HTML wiki (wiki.html) plus a plain-Markdown docs tree. Every scanned repo gets the same fixed DeepWiki-style structure — home, overview, architecture, modules, flows, onboarding, source browser, search — only the data varies per project. Zero runtime dependencies beyond Python 3 stdlib; no node, npm, or build step. Standalone / manual skill — NOT part of the /tgd-map pipeline. Use when you explicitly want to generate or regenerate a project wiki from an existing knowledge graph under $TGD_DIR/.scans/.
---

# tGD Wiki Generation (Single-File HTML, Multi-Repo)

## Overview

Compile the outputs of CodeGraph (`.codegraph/codegraph.db`) and
Understand-Anything (`.understand-anything/knowledge-graph.json`) for
**every** repo scanned in `$TGD_DIR/.scans/` into two coordinated outputs
under `$TGD_DIR/wiki/`:

1. **`wiki.html`** — one self-contained HTML file for humans. DeepWiki-style
   SPA with sidebar navigation, repo switcher, KPI cards, module/flow pages,
   Mermaid diagrams (renderer inlined), an offline source browser with line
   anchors, and client-side search. Open it by **double-clicking** — no
   server, no build, no node/npm, works offline, and can be shared by
   sending a single file.

2. **`docs/`** — plain GitHub-flavored Markdown mirroring the same structure,
   for agents (via `manifest.json`) and for hosting on GitHub, which renders
   the Markdown and Mermaid blocks natively.

**Design guarantee — uniform structure:** every project gets the SAME page
skeleton (home → overview / architecture / onboarding / modules / flows /
source / search) because the layout lives in the skill's
`assets/wiki-template.html` and the page set is fixed by
`scripts/generate-wiki.py`. Only the data varies. Users have no artifact-side
knob that can change the structure; customization means patching the skill's
assets.

## When to Use

- Invoked **manually / on demand** to build a project wiki from a knowledge graph that `/tgd-map` already produced under `$TGD_DIR/.scans/`. This skill is **not** wired into the `/tgd-map` pipeline — run it yourself when you want the wiki.
- Called again to regenerate the wiki after code changes (re-run `/tgd-map` first to refresh the knowledge graph)

## Inputs

Required:

- `$TGD_DIR` — resolved by `/tgd-map` Step 0
- `$TGD_DIR/.scans/<repo>/.understand-anything/knowledge-graph.json` for each repo

Optional:

- `$TGD_DIR/.scans/<repo>/.codegraph/` (used if `codegraph` CLI is available)
- `$TGD_DIR/wiki/wiki-prose.json` — LLM-authored prose sidecar (see below). Absent or unreadable → the generator derives descriptions from graph structure instead. It **never hard-depends** on this file, so it still runs standalone, in CI, and offline.
- `--primary <slug>` (defaults to first scan), `--dashboard-url URL`,
  `--max-source-lines N` (default 1500; caps per-file source embedding)

## Outputs

```
$TGD_DIR/
├── CONTEXT.md                    ← tGD core (untouched)
├── .scans/                       ← tGD core (untouched)
└── wiki/
    ├── wiki.html                 ← THE human-facing wiki: a CURATED overview
    │                               (system/module/flow prose + diagrams + search)
    ├── wiki-prose.json           ← LLM prose sidecar (input; see below)
    └── docs/
        ├── index.md              ← home: repo table
        ├── sources.md            ← source inventory
        ├── manifest.json         ← top-level manifest (all repos)
        └── repos/<slug>/         ← SAME tree for every repo:
            ├── index.md          ← repo home (KPIs, module/flow tables)
            ├── overview.md
            ├── architecture.md   ← Mermaid fenced blocks (GitHub renders)
            ├── onboarding.md
            ├── files.md          ← COMPREHENSIVE index: every source file, explained
            ├── files/*.md        ← one page PER FILE: explanation + symbols + source
            ├── modules/*.md      ← one per architectural layer
            ├── flows/*.md        ← one per tour step
            ├── diagrams/
            │   ├── index.md
            │   ├── architecture.mmd
            │   └── dependencies.mmd
            └── manifest.json     ← per-repo manifest
```

**Division of labor** (deliberate): `wiki.html` is the light, shareable, single-file **overview** — you open it, land on home, navigate. The `docs/` Markdown tree is the **complete reference** — the `files/` sub-tree has one explained page per source file, so "all of the code, explained" lives there (multi-file, GitHub-rendered, scales to any repo size) rather than bloating the single HTML file.

## Prose sidecar (`wiki-prose.json`)

Every page's prose resolves in this precedence: **Understand-Anything field → `wiki-prose.json` → deterministic derivation from graph structure**. So a description is never blank: if UA left it empty and no sidecar entry exists, the generator writes a true sentence computed from counts and edges (e.g. "2 files; depends on Data; used by Routes.").

The invoking agent synthesizes the sidecar (read the knowledge graph + source, write explanatory prose) before running the generator. Schema:

```json
{
  "version": 1,
  "repos": {
    "<repo-slug>": {
      "overview": "1-2 paragraph: what this repo does and how the layers fit",
      "architecture": "paragraph: the layering and dominant dependency direction",
      "onboarding": "narrative: where a new engineer should start",
      "layers":  { "<layer-name>": "what this layer is responsible for" },
      "modules": { "<module-slug>": "responsibility prose" },
      "flows":   { "<flow-slug>": "narrative of the sequence" },
      "files": {
        "<file-path>": {
          "summary": "1-2 sentences: what this file is for",
          "hash": "<content-hash>",
          "symbols": { "<symbol-name>": "purpose + gotchas" }
        }
      }
    }
  }
}
```

Every key is optional — supply what you have, the rest derives. The `hash` per file lets a re-run skip re-synthesizing unchanged files (incremental). Keep it out of the code repo; it lives under `$TGD_DIR/wiki/`.

**All prose values are Markdown.** `wiki.html` renders them with a small vendored renderer (paragraphs, `##`→`###` headings, bold/italic, inline + fenced code, lists, blockquotes, and links restricted to `#` anchors and http(s)); the `docs/` tree emits them verbatim, where GitHub renders the same Markdown natively. Multi-paragraph prose with subheadings is expected on overview/architecture pages. Per-page content bar: `overview` 2-4 paragraphs (what it does, how the layers/data-path fit, what to know before touching it); `architecture` 1-3 paragraphs (the layering and *why*); `onboarding` a narrated reading path; `layers`/`modules` 2-4 sentences each (responsibility, key files, gotcha); `flows` narrate the sequence; `files` a 1-2 sentence summary per source file with public-symbol notes. If a page's prose would read the same for any project, it's filler — ground every claim in the graph or the source you read. Raw HTML in prose is NOT rendered (it is escaped) — the renderer is escape-first by design.

The generator prints a **coverage line** per repo so the sidecar's effect is never silent — e.g. `[tGD] prose: 8 slot(s) authored; 3/12 files summarized; rest derived from graph.` A repo key in the sidecar that matches no scanned repo (a typo) is reported as ignored rather than swallowed. If prose was written but the line says "no prose sidecar", the file is in the wrong place or the JSON is malformed.

Entry points:

| Audience | Entry point | Purpose |
|---|---|---|
| Human | `$TGD_DIR/wiki/wiki.html` (double-click) | Browse the interactive wiki |
| Agent | `$TGD_DIR/wiki/docs/manifest.json` | Top-level index of every scanned repo |
| Agent (per-repo) | `$TGD_DIR/wiki/docs/repos/<slug>/manifest.json` | Deep dive into one repo |
| tGD stages | `$TGD_DIR/CONTEXT.md` | Top-level summary (unchanged) |

## Execution

```bash
python3 <SKILL_DIR>/scripts/generate-wiki.py "$TGD_DIR"
```

`<SKILL_DIR>` resolves to the directory containing this SKILL.md. One
command, ~1 second, hard-fails only when `$TGD_DIR` or every knowledge
graph is missing.

## Dependencies

| Tool | Purpose | Required? |
|---|---|---|
| Python 3.8+ | Run the generator (stdlib only) | Required — already a tGD prerequisite |
| codegraph CLI | Symbol-level enrichment | Optional |

There are **no** other dependencies. The Mermaid renderer is vendored at
`assets/vendor/mermaid.min.js` and inlined into `wiki.html` at generation
time; if the vendored file is ever missing, diagrams degrade to readable
Mermaid source text instead of failing.

## Regeneration

Re-running the skill on the same `$TGD_DIR` overwrites `wiki.html` and
`docs/` in place. `manifest.json` is regenerated fresh — do not hand-edit;
edits will be lost. Re-running on the same input produces the same structure
(timestamps aside).

## Related Skills

- `tgd-router` — Meta-skill entry point
- `understand` — Upstream: produces the knowledge graph consumed here
- `tgd-map` — Produces the `$TGD_DIR/.scans/<repo>/` knowledge graph this skill reads (this skill is standalone and no longer auto-invoked by it)

## Pitfalls

- ❌ **Do not write into the code repo.** All outputs go under `$TGD_DIR/`.
- ❌ **Do not hand-edit `manifest.json` or `wiki.html`** — regenerated on every run.
- ❌ **Do not add external requests to the template** — `wiki.html` must stay
  fully offline: no CDN scripts, fonts, or fetches. Everything is inlined.
- ❌ **Do not emit raw `</script>` inside the embedded JSON** — the generator
  escapes `</` as `<\/`; keep that invariant if you touch the embedding code.
- ❌ **Unbounded source embedding** — huge repos would bloat `wiki.html`;
  the `--max-source-lines` cap (with a visible "truncated" marker) is mandatory.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "A static site generator would look nicer." | The template already gives dark mode, Mermaid, search, and a uniform layout — with zero dependencies. An SSG re-adds node/npm, a build step, and version drift for no structural gain. |
| "Users should be able to customize the theme." | Uniform layout is the design guarantee. Users who want a custom theme fork the skill and patch `assets/wiki-template.html`. |
| "Embed all source, caps are annoying." | A monorepo with thousands of files would produce a wiki too large to open. Caps with explicit truncation markers keep the single-file promise honest. |
| "Skip the Markdown tree, HTML is enough." | Agents consume `manifest.json` + `docs/*.md`; GitHub renders them for free. The two outputs share one data model — emitting both is nearly free. |

## Red Flags

- Emitting pages that reference nodes not present in the knowledge graph
- Writing anywhere outside `$TGD_DIR/` (code repo, `$HOME`, `/tmp` beyond scratch)
- `wiki.html` making any network request when opened
- Generating `manifest.json` without listing every page written to disk
- Leaving stale files behind on regeneration
- Structure varying between projects — the page set is fixed; only data varies

## Verification

After running this skill:

- [ ] `$TGD_DIR/wiki/wiki.html` exists and opens in a browser with no console errors
- [ ] `wiki.html` renders: home (repo grid or repo home), overview, architecture
      with Mermaid SVGs, module pages with symbol tables, source browser with
      line highlight (`?L=<n>`), and search returning results
- [ ] `$TGD_DIR/wiki/docs/index.md` exists (home: repo table)
- [ ] `$TGD_DIR/wiki/docs/manifest.json` exists with a `repos` array (one entry per scan) and `wikiHtml` key
- [ ] For each repo scanned:
  - [ ] `docs/repos/<slug>/index.md`, `overview.md`, `architecture.md`, `onboarding.md` exist
  - [ ] `docs/repos/<slug>/files.md` exists and `files/` has one page per source file
  - [ ] No description cell is blank — prose came from the sidecar or was derived
  - [ ] `docs/repos/<slug>/modules/` contains one page per layer
  - [ ] `docs/repos/<slug>/flows/` contains one page per tour step (or is empty if no tour)
  - [ ] `docs/repos/<slug>/diagrams/architecture.mmd` and `dependencies.mmd` exist
  - [ ] `docs/repos/<slug>/manifest.json` exists
- [ ] No files were written outside `$TGD_DIR/`
- [ ] Re-running the skill on the same input produces the same structure (idempotent)
