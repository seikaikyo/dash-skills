#!/usr/bin/env python3
"""
generate-wiki.py — Compile Understand-Anything + CodeGraph outputs into a
self-contained static wiki under $TGD_DIR/wiki/.

Called by /tgd-map Step 6 (via the tgd-wiki-generation skill).

Two outputs, one data model:

1. wiki.html — a single self-contained HTML file (DeepWiki-style SPA:
   home, overview, architecture, modules, flows, onboarding, source
   browser, search). All data and the Mermaid renderer are inlined —
   open it by double-clicking, no server, no build step, no node/npm.

2. docs/ — plain GitHub-flavored Markdown mirroring the same structure,
   for agents and for hosting on GitHub (which renders Mermaid natively).

Every repo scanned in $TGD_DIR/.scans/<slug>/ gets the SAME page
structure — the layout is fixed by this generator and the HTML template;
only the data varies per project.

Usage:
    python3 generate-wiki.py <TGD_DIR> [--primary <slug>]
                             [--dashboard-url URL] [--max-source-lines N]
                             [--quiet]

Inputs:
    $TGD_DIR/.scans/<slug>/.understand-anything/knowledge-graph.json  (required per repo)
    $TGD_DIR/.scans/<slug>/.codegraph/                                (optional)

Outputs (all under $TGD_DIR/wiki/):
    wiki.html                               ← the human-facing wiki (single file)
    docs/index.md                           ← home: repo table
    docs/sources.md                         ← shared: source inventory
    docs/manifest.json                      ← top-level manifest (all repos)
    docs/repos/<slug>/index.md              ← per-repo home
    docs/repos/<slug>/overview.md
    docs/repos/<slug>/architecture.md
    docs/repos/<slug>/onboarding.md
    docs/repos/<slug>/modules/*.md
    docs/repos/<slug>/flows/*.md
    docs/repos/<slug>/diagrams/index.md
    docs/repos/<slug>/diagrams/architecture.mmd
    docs/repos/<slug>/diagrams/dependencies.mmd
    docs/repos/<slug>/manifest.json         ← per-repo manifest

No external dependencies — Python 3.8+ stdlib only.
Fails hard on unrecoverable errors (missing $TGD_DIR, no knowledge graph).
Degrades gracefully when optional per-repo data is missing.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

GENERATOR_VERSION = "0.6.1"
ENGINE = "static-html"
SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATE_FILE = SKILL_DIR / "assets" / "wiki-template.html"
MERMAID_FILE = SKILL_DIR / "assets" / "vendor" / "mermaid.min.js"
DEFAULT_MAX_SOURCE_LINES = 1500


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------


@dataclass
class WikiModel:
    project: Dict[str, Any]
    layers: List[Dict[str, Any]]
    tour: List[Dict[str, Any]]
    nodes: List[Dict[str, Any]]
    edges: List[Dict[str, Any]]
    modules: List[Dict[str, Any]] = field(default_factory=list)
    flows: List[Dict[str, Any]] = field(default_factory=list)
    entry_points: List[Dict[str, Any]] = field(default_factory=list)
    repo_slug: str = ""
    repo_path: str = ""
    dashboard_url: Optional[str] = None
    architecture_mermaid: str = ""
    dependency_mermaid: str = ""
    node_paths: Dict[str, str] = field(default_factory=dict)
    source_files: List[Dict[str, Any]] = field(default_factory=list)
    generated_at: str = ""
    # LLM-authored prose sidecar for this repo (may be empty — the generator
    # never hard-depends on it; missing prose falls back to derivation).
    prose: Dict[str, Any] = field(default_factory=dict)


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------


_SLUG_RX = re.compile(r"[^a-z0-9]+")

_LAYER_ACCENT_HINTS: List[Tuple[re.Pattern, str]] = [
    (re.compile(r"ui|front", re.I), "ui"),
    (re.compile(r"api|route|http|controller", re.I), "api"),
    (re.compile(r"domain|service|business", re.I), "domain"),
    (re.compile(r"persist|db|database|model|repo", re.I), "persistence"),
    (re.compile(r"infra|deploy|docker|ops", re.I), "infra"),
]

_LAYER_ICON_HINTS: List[Tuple[re.Pattern, str]] = [
    (re.compile(r"ui|front", re.I), "🎨"),
    (re.compile(r"api|route|http", re.I), "🔌"),
    (re.compile(r"domain|service|business", re.I), "🧠"),
    (re.compile(r"persist|db|database|model|repo", re.I), "🗄️"),
    (re.compile(r"infra|deploy|docker|ops", re.I), "⚙️"),
]


def slugify(text: str) -> str:
    slug = _SLUG_RX.sub("-", (text or "").lower()).strip("-")
    return slug or "unnamed"


def infer_layer_accent(name: str) -> str:
    for rx, accent in _LAYER_ACCENT_HINTS:
        if rx.search(name or ""):
            return accent
    return "default"


def infer_layer_icon(name: str) -> str:
    for rx, icon in _LAYER_ICON_HINTS:
        if rx.search(name or ""):
            return icon
    return "🧩"


def log(msg: str, *, quiet: bool = False) -> None:
    if not quiet:
        sys.stderr.write(f"[tgd-wiki] {msg}\n")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False), encoding="utf-8")


def md_cell(text: str) -> str:
    """Escape a value for a GitHub-flavored Markdown table cell."""
    if not text:
        return ""
    return str(text).replace("|", r"\|").replace("\n", " ").strip()


# ---------------------------------------------------------------------------
# Scan discovery
# ---------------------------------------------------------------------------


def discover_repos(tgd_dir: Path) -> List[Tuple[str, Path]]:
    scans = tgd_dir / ".scans"
    if not scans.is_dir():
        return []
    repos: List[Tuple[str, Path]] = []
    for entry in sorted(scans.iterdir()):
        if entry.is_dir() and (entry / ".understand-anything" / "knowledge-graph.json").is_file():
            repos.append((entry.name, entry))
    return repos


def pick_primary_slug(
    repos: List[Tuple[str, Path]], requested: Optional[str]
) -> str:
    if not repos:
        raise SystemExit(
            "No repos with a knowledge-graph.json found under $TGD_DIR/.scans/. "
            "Run /tgd-map Step 4 first."
        )
    if requested:
        for slug, _ in repos:
            if slug == requested:
                return slug
        raise SystemExit(
            f"Requested primary repo '{requested}' not found. Available: "
            + ", ".join(s for s, _ in repos)
        )
    return repos[0][0]


# ---------------------------------------------------------------------------
# Model building
# ---------------------------------------------------------------------------


FILE_LEVEL_TYPES = {
    "file", "config", "document", "service", "pipeline",
    "table", "schema", "resource", "endpoint",
}


SYMBOL_TYPES = {"function", "class", "method", "interface", "type", "enum", "component"}


def explicit_line(node: Dict[str, Any]) -> Optional[int]:
    """Read line number from common graph schemas, if present."""
    for key in ("startLine", "line", "lineNumber", "lineno"):
        value = node.get(key)
        if isinstance(value, int) and value > 0:
            return value
    for key in ("range", "location", "loc"):
        value = node.get(key) or {}
        if isinstance(value, dict):
            start = value.get("start") or value.get("begin") or {}
            if isinstance(start, dict):
                line = start.get("line") or start.get("lineNumber")
                if isinstance(line, int) and line > 0:
                    return line
    return None


def infer_symbol_line(repo_root: Path, file_path: str, symbol_name: str) -> Optional[int]:
    """Best-effort offline symbol locator.

    UA graphs do not consistently include line numbers. When the local source
    file exists, infer the line with conservative regexes. If no match is found,
    callers fall back to the file-level view.
    """
    if not repo_root or not file_path or not symbol_name:
        return None
    path = (repo_root / file_path).resolve()
    try:
        if not path.is_file() or repo_root.resolve() not in path.parents:
            return None
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception:
        return None

    escaped = re.escape(symbol_name)
    patterns = [
        rf"^\s*(async\s+)?def\s+{escaped}\s*\(",
        rf"^\s*class\s+{escaped}\b",
        rf"^\s*(export\s+)?(async\s+)?function\s+{escaped}\s*\(",
        rf"^\s*(export\s+)?(const|let|var)\s+{escaped}\s*=",
        rf"^\s*(export\s+)?class\s+{escaped}\b",
        rf"^\s*(export\s+)?interface\s+{escaped}\b",
        rf"^\s*(export\s+)?type\s+{escaped}\b",
        rf"^\s*{escaped}\s*[:=]\s*",  # object method / property shorthand
    ]
    for i, line in enumerate(lines, start=1):
        if any(re.search(p, line) for p in patterns):
            return i
    return None


def collect_source_files(
    nodes: List[Dict[str, Any]], repo_root: Path, max_lines: int
) -> List[Dict[str, Any]]:
    seen: Dict[str, Dict[str, Any]] = {}
    for n in nodes:
        fp = n.get("filePath") or n.get("path") or ""
        if not fp:
            continue
        item = seen.setdefault(fp, {
            "path": fp,
            "available": False,
            "truncated": False,
            "line_count": 0,
            "language": language_for_path(fp),
            "lines": [],
        })
        full = (repo_root / fp).resolve() if repo_root else Path(fp)
        try:
            if repo_root and full.is_file() and repo_root.resolve() in full.parents:
                raw_lines = full.read_text(encoding="utf-8", errors="replace").splitlines()
                item["available"] = True
                item["line_count"] = len(raw_lines)
                if len(raw_lines) > max_lines:
                    item["truncated"] = True
                    raw_lines = raw_lines[:max_lines]
                item["lines"] = raw_lines
        except Exception:
            pass
    return sorted(seen.values(), key=lambda x: x["path"])


def language_for_path(file_path: str) -> str:
    ext = Path(file_path).suffix.lower().lstrip(".")
    return {
        "py": "python",
        "ts": "typescript",
        "tsx": "tsx",
        "js": "javascript",
        "jsx": "jsx",
        "rs": "rust",
        "go": "go",
        "java": "java",
        "kt": "kotlin",
        "swift": "swift",
        "rb": "ruby",
        "php": "php",
        "cs": "csharp",
        "cpp": "cpp",
        "c": "c",
        "h": "c",
        "md": "markdown",
        "json": "json",
        "yaml": "yaml",
        "yml": "yaml",
        "toml": "toml",
        "sh": "bash",
    }.get(ext, "text")


def _node_map(nodes: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {n["id"]: n for n in nodes if "id" in n}


def _node_paths(nodes: List[Dict[str, Any]]) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for n in nodes:
        nid = n.get("id")
        if not nid:
            continue
        result[nid] = n.get("filePath") or n.get("path") or n.get("name") or nid
    return result


def build_modules(
    layers: List[Dict[str, Any]],
    node_map: Dict[str, Dict[str, Any]],
    edges: List[Dict[str, Any]],
    repo_root: Path,
) -> List[Dict[str, Any]]:
    modules: List[Dict[str, Any]] = []
    for layer in layers:
        title = layer.get("name") or layer.get("id") or "unnamed"
        slug = slugify(title)
        node_ids = layer.get("nodeIds") or layer.get("nodes") or []
        files: List[Dict[str, Any]] = []
        symbols: List[Dict[str, Any]] = []
        for nid in node_ids:
            node = node_map.get(nid)
            if not node:
                continue
            ntype = node.get("type")
            path = node.get("filePath") or node.get("path") or node.get("name") or nid
            if ntype in FILE_LEVEL_TYPES:
                files.append({"path": path, "summary": node.get("summary") or ""})
            elif ntype in SYMBOL_TYPES:
                symbol_file = node.get("filePath") or node.get("path") or ""
                line = explicit_line(node) or infer_symbol_line(
                    repo_root, symbol_file, node.get("name") or nid
                )
                symbols.append({
                    "name": node.get("name") or nid,
                    "file": symbol_file,
                    "line": line,
                    "summary": node.get("summary") or "",
                })
        symbols_capped = sorted(symbols, key=lambda s: s["name"])[:40]
        module_ids = set(node_ids)
        dep_mermaid = _module_dependency_mermaid(module_ids, edges, node_map, title)
        modules.append({
            "id": layer.get("id") or f"layer:{slug}",
            "title": title,
            "slug": slug,
            "summary": layer.get("description") or "",
            "files": files,
            "symbols": symbols_capped,
            "dependency_mermaid": dep_mermaid,
            "node_ids": sorted(module_ids),
            "file_count": len(files),
            "symbol_count": len(symbols_capped),
            "icon": infer_layer_icon(title),
            "accent": infer_layer_accent(title),
        })
    return modules


def _module_dependency_mermaid(
    module_ids: set,
    edges: List[Dict[str, Any]],
    node_map: Dict[str, Dict[str, Any]],
    label: str,
) -> str:
    subset = [
        e for e in edges
        if e.get("source") in module_ids and e.get("target") in module_ids
    ]
    if not subset:
        return f"graph TD\n  A[No internal edges in {label}]"
    lines = ["graph TD"]
    for e in subset[:60]:
        s = node_map.get(e["source"], {}).get("name") or e["source"]
        t = node_map.get(e["target"], {}).get("name") or e["target"]
        etype = e.get("type") or "->"
        lines.append(f'  {_mm_id(s)}[{s}] -->|{etype}| {_mm_id(t)}[{t}]')
    if len(subset) > 60:
        lines.append(f"  %% Truncated: {len(subset) - 60} more edges omitted")
    return "\n".join(lines)


def _mm_id(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", name)[:80] or "n"


def build_flows(
    tour: List[Dict[str, Any]], node_paths: Dict[str, str]
) -> List[Dict[str, Any]]:
    flows: List[Dict[str, Any]] = []
    for step in tour or []:
        title = step.get("title") or f"Step {step.get('order', '?')}"
        slug = slugify(title)
        files = [
            {"path": node_paths.get(nid, nid)}
            for nid in step.get("nodeIds") or []
        ]
        flows.append({
            "title": title,
            "slug": slug,
            "description": step.get("description") or "",
            "mermaid": _flow_sequence_mermaid(title, files),
            "files": files,
            "order": step.get("order", 0),
        })
    return flows


def _flow_sequence_mermaid(title: str, files: List[Dict[str, Any]]) -> str:
    if not files:
        return f"sequenceDiagram\n  Note over Flow: {title} (no files captured)"
    lines = ["sequenceDiagram"]
    actors: List[str] = []
    seen_actors = set()
    for f in files:
        actor = _mm_id(Path(f["path"]).stem or "step")
        if actor not in seen_actors:
            lines.append(f"  participant {actor}")
            seen_actors.add(actor)
        actors.append(actor)
    for i, actor in enumerate(actors):
        if i == 0:
            lines.append(f"  Note over {actor}: start")
        else:
            lines.append(f"  {actors[i-1]}->>+{actor}: next")
    return "\n".join(lines)


def build_architecture_mermaid(
    layers: List[Dict[str, Any]], edges: List[Dict[str, Any]]
) -> str:
    if not layers:
        return "graph TD\n  A[No layers detected]"
    node_to_layer: Dict[str, str] = {}
    for l in layers:
        for nid in l.get("nodeIds") or []:
            node_to_layer[nid] = l.get("id") or slugify(l.get("name") or "layer")
    layer_edges: Dict[Tuple[str, str], int] = {}
    for e in edges:
        src = e.get("source") or ""
        tgt = e.get("target") or ""
        s = node_to_layer.get(src)
        t = node_to_layer.get(tgt)
        if s and t and s != t:
            layer_edges[(s, t)] = layer_edges.get((s, t), 0) + 1
    lines = ["graph TD"]
    for l in layers:
        lid = l.get("id") or slugify(l.get("name") or "layer")
        lname = l.get("name") or lid
        lines.append(f'  {_mm_id(lid)}["{lname}"]')
    for (s, t), weight in sorted(layer_edges.items(), key=lambda kv: (-kv[1], kv[0]))[:30]:
        lines.append(f"  {_mm_id(s)} -->|{weight}| {_mm_id(t)}")
    return "\n".join(lines)


def build_dependency_mermaid(
    edges: List[Dict[str, Any]], node_map: Dict[str, Dict[str, Any]]
) -> str:
    counts: Dict[str, int] = {}
    for e in edges:
        counts[e.get("source", "")] = counts.get(e.get("source", ""), 0) + 1
        counts[e.get("target", "")] = counts.get(e.get("target", ""), 0) + 1
    top_list = [nid for nid, _ in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:25]]
    top = set(top_list)
    if not top_list:
        return "graph TD\n  A[No edges]"
    lines = ["graph LR"]
    for nid in top_list:
        n = node_map.get(nid, {})
        lbl = n.get("name") or nid
        lines.append(f'  {_mm_id(nid)}["{lbl}"]')
    seen = 0
    for e in edges:
        if e.get("source") in top and e.get("target") in top:
            lines.append(f"  {_mm_id(e['source'])} --> {_mm_id(e['target'])}")
            seen += 1
            if seen >= 80:
                lines.append("  %% Truncated after 80 edges")
                break
    return "\n".join(lines)


def detect_entry_points(
    nodes: List[Dict[str, Any]], edges: Optional[List[Dict[str, Any]]] = None
) -> List[Dict[str, Any]]:
    """Detect entry points two ways and merge:
    (1) filename / tag signals (main.py, index.ts, an `entry` tag, …);
    (2) graph topology — file-level nodes that drive others but nothing calls
        them (out-edges > 0, in-edges == 0). Pure filename matching missed real
        entry points (e.g. an Express `app.ts` not named in the list); topology
        catches them. Test/spec files are excluded from the topology signal."""
    edges = edges or []
    entry_patterns = (
        "main.py", "__main__.py", "manage.py",
        "index.ts", "index.js", "main.ts", "main.tsx",
        "app.py", "app.ts", "server.ts", "server.js",
        "cmd/", "src/main.rs", "cli.py",
        "wsgi.py", "asgi.py",
    )
    indeg: Dict[str, int] = {}
    outdeg: Dict[str, int] = {}
    for e in edges:
        outdeg[e.get("source")] = outdeg.get(e.get("source"), 0) + 1
        indeg[e.get("target")] = indeg.get(e.get("target"), 0) + 1

    def is_testish(fp: str) -> bool:
        low = fp.lower()
        return any(t in low for t in (".test.", ".spec.", "_test.", "/tests/", "/__tests__/"))

    hits: List[Dict[str, Any]] = []
    seen = set()
    for n in nodes:
        fp = n.get("filePath") or n.get("path") or ""
        if not fp or fp in seen:
            continue
        tags = n.get("tags") or []
        nid = n.get("id")
        by_name = any(fp.endswith(p) or f"/{p}" in f"/{fp}" for p in entry_patterns) or "entry" in tags
        by_topology = (
            n.get("type") in FILE_LEVEL_TYPES
            and outdeg.get(nid, 0) > 0
            and indeg.get(nid, 0) == 0
            and not is_testish(fp)
        )
        if by_name or by_topology:
            seen.add(fp)
            hits.append({"path": fp, "kind": "entry" if by_name else "root"})
        if len(hits) >= 12:
            break
    return hits


# ---------------------------------------------------------------------------
# Model compile (one per repo)
# ---------------------------------------------------------------------------


def compile_repo_model(
    graph: Dict[str, Any],
    repo_slug: str,
    repo_path: str,
    repo_root: Path,
    dashboard_url: Optional[str],
    max_source_lines: int,
) -> WikiModel:
    project = graph.get("project") or {}
    layers = graph.get("layers") or []
    tour = graph.get("tour") or []
    nodes = graph.get("nodes") or []
    edges = graph.get("edges") or []

    enriched_layers: List[Dict[str, Any]] = []
    for l in layers:
        nl = dict(l)
        nl["accent"] = infer_layer_accent(l.get("name") or "")
        nl["node_count"] = len(l.get("nodeIds") or [])
        enriched_layers.append(nl)

    node_map = _node_map(nodes)
    node_paths = _node_paths(nodes)
    modules = build_modules(enriched_layers, node_map, edges, repo_root)
    flows = build_flows(tour, node_paths)
    entry_points = detect_entry_points(nodes, edges)
    arch_mm = build_architecture_mermaid(enriched_layers, edges)
    dep_mm = build_dependency_mermaid(edges, node_map)
    source_files = collect_source_files(nodes, repo_root, max_source_lines)

    return WikiModel(
        project=dict(project) if isinstance(project, dict) else {"name": str(project or "")},
        layers=enriched_layers,
        tour=tour,
        nodes=nodes,
        edges=edges,
        modules=modules,
        flows=flows,
        entry_points=entry_points,
        repo_slug=repo_slug,
        repo_path=repo_path,
        dashboard_url=dashboard_url,
        architecture_mermaid=arch_mm,
        dependency_mermaid=dep_mm,
        node_paths=node_paths,
        source_files=source_files,
        generated_at=datetime.now(timezone.utc).isoformat(timespec="seconds"),
    )


def infer_repo_path(scan_dir: Path, project: Any) -> str:
    # project can be a dict (real UA output), a string (simple graph),
    # or None — handle all three defensively.
    if isinstance(project, dict):
        root = project.get("rootPath") or project.get("primaryRepoPath")
        if root:
            return root
        name = project.get("name") or ""
    elif isinstance(project, str):
        name = project
    else:
        name = ""
    home = Path.home()
    guess = home / (name or scan_dir.name)
    return str(guess if guess.is_dir() else (scan_dir.name if not name else name))


# ---------------------------------------------------------------------------
# Markdown emission (agent-facing; GitHub renders Mermaid natively)
# ---------------------------------------------------------------------------


def _kpi_of(model: WikiModel) -> Dict[str, int]:
    return {
        "files": sum(1 for n in model.nodes if n.get("type") in FILE_LEVEL_TYPES),
        "modules": len(model.modules),
        "flows": len(model.flows),
        "edges": len(model.edges),
    }


def _md_header(title: str, model: WikiModel) -> str:
    return f"# {title}\n\n> Repo: `{model.repo_slug}` · Generated: {model.generated_at} · tgd-wiki-generation v{GENERATOR_VERSION}\n\n"


# ---------------------------------------------------------------------------
# Prose resolution: UA field -> LLM sidecar (wiki-prose.json) -> derivation.
# The wiki must never show a blank description. When Understand-Anything left a
# field empty and no sidecar prose exists, we derive a factual sentence from the
# graph structure (edges, counts) so every page states something true. The
# generator never hard-depends on the sidecar — missing prose degrades to
# derivation, so it still runs standalone (python3 only, CI, offline).
# ---------------------------------------------------------------------------


def _first_nonempty(*vals: Any) -> str:
    for v in vals:
        if v and str(v).strip():
            return str(v).strip()
    return ""


def _layer_key(l: Dict[str, Any]) -> str:
    return l.get("name") or l.get("id") or "unnamed"


def _layer_of_node(model: WikiModel) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for l in model.layers:
        key = _layer_key(l)
        for nid in (l.get("nodeIds") or l.get("nodes") or []):
            out[nid] = key
    return out


def layer_dependencies(model: WikiModel) -> Dict[str, Dict[str, set]]:
    """layer -> {'out': layers it depends on, 'in': layers that depend on it}."""
    ln = _layer_of_node(model)
    rel: Dict[str, Dict[str, set]] = {_layer_key(l): {"out": set(), "in": set()} for l in model.layers}
    for e in model.edges:
        s, t = ln.get(e.get("source")), ln.get(e.get("target"))
        if s and t and s != t:
            rel.setdefault(s, {"out": set(), "in": set()})["out"].add(t)
            rel.setdefault(t, {"out": set(), "in": set()})["in"].add(s)
    return rel


def derive_layer_desc(layer: Dict[str, Any], layer_rel: Dict[str, Dict[str, set]]) -> str:
    n = layer.get("node_count", 0)
    rel = layer_rel.get(_layer_key(layer), {"out": set(), "in": set()})
    parts = [f"{n} file{'s' if n != 1 else ''}"]
    if rel["out"]:
        parts.append("depends on " + ", ".join(sorted(rel["out"])))
    if rel["in"]:
        parts.append("used by " + ", ".join(sorted(rel["in"])))
    return "; ".join(parts) + "."


def resolve_layer_desc(model: WikiModel, layer: Dict[str, Any], layer_rel) -> str:
    prose_layers = model.prose.get("layers") or {}
    return _first_nonempty(
        layer.get("description"),
        prose_layers.get(_layer_key(layer)),
        derive_layer_desc(layer, layer_rel),
    )


def resolve_overview(model: WikiModel) -> str:
    prose = _first_nonempty(model.prose.get("overview"), model.project.get("description"))
    if prose:
        return prose
    name = model.project.get("name") or model.repo_slug
    langs = ", ".join(model.project.get("languages") or []) or "an unspecified stack"
    fw = model.project.get("frameworks") or []
    fw_s = f" using {', '.join(fw)}" if fw else ""
    names = [l.get("name") for l in model.layers if l.get("name")]
    layer_s = (f" It is organized into {len(names)} layers: " + ", ".join(names) + ".") if names else ""
    return f"{name} is written in {langs}{fw_s}.{layer_s}"


def resolve_architecture(model: WikiModel, layer_rel) -> str:
    prose = _first_nonempty(model.prose.get("architecture"))
    if prose:
        return prose
    if not model.layers:
        return "No architectural layers were detected in the knowledge graph."
    roots = [n for n, r in layer_rel.items() if r["in"] and not r["out"]]
    leaves = [n for n, r in layer_rel.items() if r["out"] and not r["in"]]
    bits = [f"{len(model.layers)} layers"]
    if leaves:
        bits.append("entry-facing: " + ", ".join(sorted(leaves)))
    if roots:
        bits.append("foundational: " + ", ".join(sorted(roots)))
    return "; ".join(bits) + "."


def resolve_module_summary(model: WikiModel, m: Dict[str, Any]) -> str:
    prose_mods = model.prose.get("modules") or {}
    derived = (f"{m['file_count']} file{'s' if m['file_count'] != 1 else ''}, "
               f"{m['symbol_count']} symbol{'s' if m['symbol_count'] != 1 else ''}.")
    return _first_nonempty(m.get("summary"), prose_mods.get(m["slug"]), derived)


def resolve_flow_desc(model: WikiModel, f: Dict[str, Any]) -> str:
    prose_flows = model.prose.get("flows") or {}
    derived = f"Sequence across {len(f.get('files') or [])} files."
    return _first_nonempty(f.get("description"), prose_flows.get(f["slug"]), derived)


def resolve_onboarding(model: WikiModel) -> str:
    return _first_nonempty(model.prose.get("onboarding"), "Suggested reading path through the codebase.")


def _prose_file(model: WikiModel, path: str) -> Dict[str, Any]:
    return (model.prose.get("files") or {}).get(path) or {}


def resolve_file_summary(model: WikiModel, path: str) -> str:
    derived = f"{language_for_path(path)} file at `{path}`."
    return _first_nonempty(_prose_file(model, path).get("summary"), derived)


def resolve_symbol_purpose(model: WikiModel, path: str, sym: Dict[str, Any]) -> str:
    psyms = _prose_file(model, path).get("symbols") or {}
    return _first_nonempty(sym.get("summary"), psyms.get(sym.get("name")))


def symbols_by_file(model: WikiModel) -> Dict[str, List[Dict[str, Any]]]:
    out: Dict[str, List[Dict[str, Any]]] = {}
    for m in model.modules:
        for s in m.get("symbols") or []:
            f = s.get("file") or ""
            if f:
                out.setdefault(f, []).append(s)
    return out


def emit_file_pages(model: WikiModel, repo_dir: Path) -> List[Dict[str, str]]:
    """Comprehensive per-file reference — one page per source file with an
    explanation, its important symbols, and the full source. This is where
    complete coverage lives; the single-file wiki.html stays a curated
    overview. Returns the index rows (path, page, summary) for manifests."""
    sbf = symbols_by_file(model)
    rows: List[Dict[str, str]] = []
    index = [_md_header("Files", model), "Every source file, explained.\n",
             "| File | Summary |\n|---|---|"]
    for sf in model.source_files:
        path = sf["path"]
        page_rel = slugify(path) + ".md"
        summary = resolve_file_summary(model, path)
        rows.append({"path": path, "page": f"files/{page_rel}", "summary": summary})
        index.append(f"| [`{md_cell(path)}`](files/{page_rel}) | {md_cell(summary)} |")

        lines = [_md_header(f"📄 {path}", model), summary + "\n"]
        syms = sbf.get(path) or []
        if syms:
            lines.append("## Symbols\n\n| Symbol | Line | Purpose |\n|---|---:|---|")
            for s in syms:
                purpose = resolve_symbol_purpose(model, path, s) or "_(derived)_"
                lines.append(f"| `{md_cell(s['name'])}` | {s.get('line') or '—'} | {md_cell(purpose)} |")
            lines.append("")
        if sf.get("available") and sf.get("lines"):
            trunc = ", truncated" if sf.get("truncated") else ""
            lines.append(f"## Source ({sf['line_count']} lines{trunc})\n")
            lines.append(f"```{sf.get('language') or 'text'}")
            lines.extend(sf["lines"])
            lines.append("```")
        else:
            lines.append("_Source not embedded (file not accessible at generation time)._")
        write_text(repo_dir / "files" / page_rel, "\n".join(lines) + "\n")
    write_text(repo_dir / "files.md", "\n".join(index) + "\n")
    return rows


def emit_repo_md(model: WikiModel, repo_dir: Path) -> None:
    name = model.project.get("name") or model.repo_slug
    kpi = _kpi_of(model)
    layer_rel = layer_dependencies(model)

    # index.md
    lines = [_md_header(f"{name} — Project Wiki", model)]
    lines.append(f"{resolve_overview(model)}\n")
    lines.append("| Files | Modules | Flows | Dependencies |\n|---:|---:|---:|---:|")
    lines.append(f"| {kpi['files']} | {kpi['modules']} | {kpi['flows']} | {kpi['edges']} |\n")
    lines.append("## Contents\n")
    lines.append("- [Overview](overview.md)\n- [Architecture](architecture.md)\n- [Onboarding](onboarding.md)\n- [Files](files.md) — every source file, explained\n- [Diagrams](diagrams/index.md)\n")
    if model.modules:
        lines.append("## Modules\n\n| Module | Files | Symbols | Summary |\n|---|---:|---:|---|")
        for m in model.modules:
            lines.append(f"| {m['icon']} [{md_cell(m['title'])}](modules/{m['slug']}.md) | {m['file_count']} | {m['symbol_count']} | {md_cell(resolve_module_summary(model, m))} |")
        lines.append("")
    if model.flows:
        lines.append("## Flows\n\n| Flow | Description |\n|---|---|")
        for f in model.flows:
            lines.append(f"| [{md_cell(f['title'])}](flows/{f['slug']}.md) | {md_cell(resolve_flow_desc(model, f))} |")
        lines.append("")
    write_text(repo_dir / "index.md", "\n".join(lines))

    # overview.md
    lines = [_md_header("Overview", model)]
    lines.append(f"{resolve_overview(model)}\n")
    lines.append("## Tech\n\n| | |\n|---|---|")
    lines.append(f"| Languages | {md_cell(', '.join(model.project.get('languages') or [])) or '—'} |")
    lines.append(f"| Frameworks | {md_cell(', '.join(model.project.get('frameworks') or [])) or '—'} |")
    lines.append(f"| Repo path | `{model.repo_path}` |\n")
    lines.append("## Layers\n\n| Layer | Nodes | Description |\n|---|---:|---|")
    for l in model.layers:
        lines.append(f"| **{md_cell(l.get('name') or '')}** | {l['node_count']} | {md_cell(resolve_layer_desc(model, l, layer_rel))} |")
    lines.append("")
    lines.append("## Entry Points\n")
    if model.entry_points:
        for e in model.entry_points:
            lines.append(f"- `{e['path']}`")
    else:
        lines.append("_No entry points detected._")
    write_text(repo_dir / "overview.md", "\n".join(lines) + "\n")

    # architecture.md
    lines = [_md_header("Architecture", model)]
    lines.append(f"{resolve_architecture(model, layer_rel)}\n")
    lines.append("## Layer Diagram\n\n```mermaid\n" + model.architecture_mermaid + "\n```\n")
    lines.append("## Dependency Graph (top nodes)\n\n```mermaid\n" + model.dependency_mermaid + "\n```\n")
    lines.append("## Layers\n\n| Layer | Nodes | Description |\n|---|---:|---|")
    for l in model.layers:
        lines.append(f"| **{md_cell(l.get('name') or '')}** | {l['node_count']} | {md_cell(resolve_layer_desc(model, l, layer_rel))} |")
    write_text(repo_dir / "architecture.md", "\n".join(lines) + "\n")

    # onboarding.md
    lines = [_md_header("Onboarding", model)]
    lines.append(f"{resolve_onboarding(model)}\n")
    if model.tour:
        for i, t in enumerate(model.tour, start=1):
            lines.append(f"## Step {i}: {t.get('title') or ''}\n")
            lines.append(f"{t.get('description') or ''}\n")
            for nid in t.get("nodeIds") or []:
                lines.append(f"- `{model.node_paths.get(nid, nid)}`")
            lines.append("")
    else:
        lines.append("_No tour steps captured._")
    write_text(repo_dir / "onboarding.md", "\n".join(lines) + "\n")

    # modules/*.md
    for m in model.modules:
        lines = [_md_header(f"{m['icon']} {m['title']} Module", model)]
        lines.append("## Responsibility\n")
        lines.append(f"{resolve_module_summary(model, m)}\n")
        lines.append("## Key Files\n")
        if m["files"]:
            lines.append("| File | Role |\n|---|---|")
            for f in m["files"]:
                role = _first_nonempty(f.get("summary"), resolve_file_summary(model, f["path"]))
                lines.append(f"| [`{md_cell(f['path'])}`](../files/{slugify(f['path'])}.md) | {md_cell(role)} |")
        else:
            lines.append("_No files were mapped into this module._")
        if m["symbols"]:
            lines.append("\n## Important Symbols\n\n| Symbol | File | Line | Purpose |\n|---|---|---:|---|")
            for s in m["symbols"]:
                purpose = resolve_symbol_purpose(model, s.get("file") or "", s) or "_(derived)_"
                lines.append(f"| `{md_cell(s['name'])}` | {('`' + s['file'] + '`') if s['file'] else '—'} | {s.get('line') or '—'} | {md_cell(purpose)} |")
        lines.append("\n## Dependencies\n\n```mermaid\n" + m["dependency_mermaid"] + "\n```")
        write_text(repo_dir / "modules" / f"{m['slug']}.md", "\n".join(lines) + "\n")

    # flows/*.md
    for f in model.flows:
        lines = [_md_header(f"🔀 {f['title']}", model)]
        lines.append(f"{resolve_flow_desc(model, f)}\n")
        lines.append("## Sequence\n\n```mermaid\n" + f["mermaid"] + "\n```\n")
        lines.append("## Files Involved\n")
        if f["files"]:
            for x in f["files"]:
                lines.append(f"- `{x['path']}`")
        else:
            lines.append("_No files captured for this flow._")
        write_text(repo_dir / "flows" / f"{f['slug']}.md", "\n".join(lines) + "\n")

    # diagrams/
    lines = [_md_header("Diagrams", model)]
    lines.append("## Architecture\n\n```mermaid\n" + model.architecture_mermaid + "\n```\n")
    lines.append("## Dependencies\n\n```mermaid\n" + model.dependency_mermaid + "\n```\n")
    lines.append("Raw Mermaid sources: [architecture.mmd](architecture.mmd) · [dependencies.mmd](dependencies.mmd)")
    write_text(repo_dir / "diagrams" / "index.md", "\n".join(lines) + "\n")
    write_text(repo_dir / "diagrams" / "architecture.mmd", model.architecture_mermaid)
    write_text(repo_dir / "diagrams" / "dependencies.mmd", model.dependency_mermaid)

    # files/ — comprehensive per-file reference (the "complete coverage" home)
    emit_file_pages(model, repo_dir)


def emit_top_md(
    docs_dir: Path,
    repo_summaries: List[Dict[str, Any]],
    primary_slug: str,
    generated_at: str,
) -> None:
    lines = [f"# tGD Project Wiki\n\n> Generated: {generated_at} · tgd-wiki-generation v{GENERATOR_VERSION}\n"]
    lines.append("Open [`../wiki.html`](../wiki.html) in a browser for the interactive wiki.\n")
    lines.append("| Repo | Modules | Flows | Description |\n|---|---:|---:|---|")
    for r in repo_summaries:
        star = " ⭐" if r["slug"] == primary_slug else ""
        lines.append(f"| [{md_cell(r['name'])}{star}](repos/{r['slug']}/index.md) | {r['module_count']} | {r['flow_count']} | {md_cell(r['description'])} |")
    write_text(docs_dir / "index.md", "\n".join(lines) + "\n")

    lines = [f"# Source Inventory\n\n> Generated: {generated_at}\n"]
    for r in repo_summaries:
        lines.append(f"## {r['name']}\n")
        lines.append(f"{r['source_count']} source files captured. Repo path: `{r['path']}`\n")
        lines.append(f"Browse them interactively in [`../wiki.html`](../wiki.html) → {r['name']} → Source.\n")
    write_text(docs_dir / "sources.md", "\n".join(lines) + "\n")


# ---------------------------------------------------------------------------
# HTML payload + rendering
# ---------------------------------------------------------------------------


def build_search_index(models: List[WikiModel]) -> List[Dict[str, Any]]:
    items: List[Dict[str, Any]] = []

    def add(title: str, item_type: str, repo: str, href: str, summary: str = "", keywords=None):
        items.append({
            "title": title,
            "type": item_type,
            "repo": repo,
            "href": href,
            "summary": summary or "",
            "keywords": keywords or [],
        })

    for model in models:
        repo = model.repo_slug
        repo_name = model.project.get("name") or repo
        base = f"/r/{repo}"
        add(repo_name, "repo", repo, base, model.project.get("description") or "",
            keywords=[repo, model.repo_path] + (model.project.get("languages") or []) + (model.project.get("frameworks") or []))
        add("Overview", "page", repo, f"{base}/overview", model.project.get("description") or "")
        add("Architecture", "page", repo, f"{base}/architecture", "Layers and dependencies")
        add("Onboarding", "page", repo, f"{base}/onboarding", "Suggested reading path")
        add("Source Browser", "page", repo, f"{base}/source", "Offline source browser")

        for m in model.modules:
            add(m["title"], "module", repo, f"{base}/module/{m['slug']}", m.get("summary") or "",
                keywords=[f.get("path", "") for f in m.get("files") or []])
            for s in m.get("symbols") or []:
                href = f"{base}/source/{s['file']}" + (f"?L={s['line']}" if s.get("line") else "")
                add(s.get("name") or "symbol", "symbol", repo,
                    href if s.get("file") else f"{base}/source",
                    s.get("summary") or "",
                    keywords=[s.get("file") or "", m["title"], str(s.get("line") or "")])

        for f in model.flows:
            add(f["title"], "flow", repo, f"{base}/flow/{f['slug']}", f.get("description") or "")

        for sf in model.source_files:
            add(sf["path"], "source", repo, f"{base}/source/{sf['path']}",
                f"{sf.get('line_count') or 0} lines" if sf.get("available") else "Source unavailable",
                keywords=[sf.get("language") or ""])

    return items


def report_prose_coverage(
    models: List[WikiModel], all_prose: Dict[str, Any], *, quiet: bool = False
) -> None:
    """Make the prose sidecar's effect visible instead of silently falling back.
    Counts, per repo, how many descriptions came from the sidecar vs were
    derived from the graph, and warns about sidecar repo keys that match no
    scanned repo (a typo there means the whole block is silently ignored)."""
    scanned = {m.repo_slug for m in models}
    for key in all_prose:
        if key not in scanned:
            log(f"⚠️  wiki-prose.json has repo '{key}' which was not scanned — "
                f"that block is ignored. Scanned: {', '.join(sorted(scanned)) or '(none)'}",
                quiet=False)
    for m in models:
        p = m.prose or {}
        applied = sum(bool(p.get(k)) for k in ("overview", "architecture", "onboarding"))
        applied += len(p.get("layers") or {}) + len(p.get("modules") or {}) + len(p.get("flows") or {})
        files_p = p.get("files") or {}
        applied += sum(1 for f in files_p.values() if f.get("summary"))
        total_files = len(m.source_files)
        if p:
            log(f"[{m.repo_slug}] prose: {applied} slot(s) authored; "
                f"{sum(1 for f in files_p.values() if f.get('summary'))}/{total_files} files summarized; "
                f"rest derived from graph.", quiet=quiet)
        else:
            log(f"[{m.repo_slug}] no prose sidecar — all descriptions derived from graph structure.",
                quiet=quiet)


def build_payload(
    models: List[WikiModel],
    primary_slug: str,
    generated_at: str,
) -> Dict[str, Any]:
    repos = []
    for m in models:
        layer_rel = layer_dependencies(m)
        file_summaries = {sf["path"]: resolve_file_summary(m, sf["path"]) for sf in m.source_files}
        modules = []
        for mod in m.modules:
            mod = dict(mod)
            mod["summary"] = resolve_module_summary(m, mod)
            modules.append(mod)
        flows = []
        for f in m.flows:
            f = dict(f)
            f["description"] = resolve_flow_desc(m, f)
            flows.append(f)
        repos.append({
            "slug": m.repo_slug,
            "name": m.project.get("name") or m.repo_slug,
            "description": m.project.get("description") or "",
            # Synthesized/derived prose — never blank (see resolve_* helpers).
            "overview": resolve_overview(m),
            "architecture": resolve_architecture(m, layer_rel),
            "onboarding": resolve_onboarding(m),
            "fileSummaries": file_summaries,
            "path": m.repo_path,
            "languages": m.project.get("languages") or [],
            "frameworks": m.project.get("frameworks") or [],
            "kpi": _kpi_of(m),
            "layers": [
                {
                    "name": l.get("name") or "",
                    "description": resolve_layer_desc(m, l, layer_rel),
                    "node_count": l["node_count"],
                    "accent": l["accent"],
                }
                for l in m.layers
            ],
            "entryPoints": m.entry_points,
            "modules": modules,
            "flows": flows,
            "tour": [
                {
                    "title": t.get("title") or "",
                    "description": t.get("description") or "",
                    "files": [m.node_paths.get(nid, nid) for nid in t.get("nodeIds") or []],
                }
                for t in m.tour
            ],
            "architecture_mermaid": m.architecture_mermaid,
            "dependency_mermaid": m.dependency_mermaid,
            "sources": m.source_files,
            "dashboardUrl": m.dashboard_url,
        })
    return {
        "generator": {
            "name": "tgd-wiki-generation",
            "version": GENERATOR_VERSION,
            "engine": ENGINE,
            "generatedAt": generated_at,
        },
        "primary": primary_slug,
        "repos": repos,
        "searchIndex": build_search_index(models),
    }


def render_wiki_html(tgd_dir: Path, payload: Dict[str, Any], *, quiet: bool = False) -> Path:
    if not TEMPLATE_FILE.is_file():
        raise SystemExit(f"Template missing: {TEMPLATE_FILE}")
    template = TEMPLATE_FILE.read_text(encoding="utf-8")

    # `</` must not appear raw inside the JSON <script> block ("</script>"
    # would terminate it). `<\/` is an equivalent, JSON-legal escape.
    data_json = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    data_json = data_json.replace("</", "<\\/")

    mermaid_js = ""
    if MERMAID_FILE.is_file():
        mermaid_js = MERMAID_FILE.read_text(encoding="utf-8")
    else:
        log("⚠️  mermaid.min.js not vendored — diagrams will show as text.", quiet=quiet)

    out = template.replace("/*__TGD_MERMAID__*/", mermaid_js, 1)
    out = out.replace("__TGD_DATA__", data_json, 1)

    dest = tgd_dir / "wiki" / "wiki.html"
    write_text(dest, out)
    return dest


# ---------------------------------------------------------------------------
# Manifests
# ---------------------------------------------------------------------------


def build_repo_manifest(model: WikiModel) -> Dict[str, Any]:
    slug = model.repo_slug
    pages: List[Dict[str, Any]] = []

    def add(page_id: str, rel: str, page_type: str, summary: str, related=None):
        pages.append({
            "id": page_id,
            "path": rel,
            "type": page_type,
            "summary": summary,
            "relatedNodes": related or [],
        })

    add("index", f"wiki/docs/repos/{slug}/index.md", "index", f"{slug} wiki home")
    add("overview", f"wiki/docs/repos/{slug}/overview.md", "overview", model.project.get("description") or "")
    add("architecture", f"wiki/docs/repos/{slug}/architecture.md", "architecture", "Layers and dependencies")
    add("onboarding", f"wiki/docs/repos/{slug}/onboarding.md", "onboarding", "Suggested reading path")
    for m in model.modules:
        add(
            f"modules/{m['slug']}",
            f"wiki/docs/repos/{slug}/modules/{m['slug']}.md",
            "module",
            m["summary"],
            related=m.get("node_ids") or [],
        )
    for f in model.flows:
        add(
            f"flows/{f['slug']}",
            f"wiki/docs/repos/{slug}/flows/{f['slug']}.md",
            "flow",
            f["description"],
        )
    add("diagrams", f"wiki/docs/repos/{slug}/diagrams/index.md", "diagrams",
        "Architecture and dependency diagrams")
    # Comprehensive per-file reference — the "complete coverage" tree. Listed
    # here so agents reading the manifest can discover every explained file.
    add("files", f"wiki/docs/repos/{slug}/files.md", "files-index",
        "Every source file, explained")
    for sf in model.source_files:
        path = sf["path"]
        add(
            f"files/{path}",
            f"wiki/docs/repos/{slug}/files/{slugify(path)}.md",
            "file",
            resolve_file_summary(model, path),
            related=[path],
        )

    return {
        "generator": {
            "name": "tgd-wiki-generation",
            "version": GENERATOR_VERSION,
            "engine": ENGINE,
            "generatedAt": model.generated_at,
        },
        "repo": {
            "slug": model.repo_slug,
            "name": model.project.get("name") or model.repo_slug,
            "description": model.project.get("description") or "",
            "path": model.repo_path,
            "languages": model.project.get("languages") or [],
            "frameworks": model.project.get("frameworks") or [],
        },
        "wikiHtml": f"wiki/wiki.html#/r/{slug}",
        "entryPoints": model.entry_points,
        "importantFlows": [
            f"wiki/docs/repos/{slug}/flows/{f['slug']}.md" for f in model.flows
        ],
        "sourceFiles": [
            {
                "path": sf["path"],
                "language": sf["language"],
                "lines": sf["line_count"],
                "available": sf["available"],
                "wikiHref": f"wiki/wiki.html#/r/{slug}/source/{sf['path']}",
            }
            for sf in model.source_files
        ],
        "pages": pages,
    }


def build_top_manifest(
    repo_summaries: List[Dict[str, Any]],
    primary_slug: str,
    generated_at: str,
    dashboard_urls: Dict[str, Optional[str]],
) -> Dict[str, Any]:
    return {
        "generator": {
            "name": "tgd-wiki-generation",
            "version": GENERATOR_VERSION,
            "engine": ENGINE,
            "generatedAt": generated_at,
        },
        "primaryRepoSlug": primary_slug,
        "wikiHtml": "wiki/wiki.html",
        "repos": [
            {
                "slug": r["slug"],
                "name": r["name"],
                "description": r["description"],
                "path": r["path"],
                "modules": r["modules"],
                "flows": r["flows"],
                "dashboardUrl": dashboard_urls.get(r["slug"]),
                "manifestPath": f"wiki/docs/repos/{r['slug']}/manifest.json",
            }
            for r in repo_summaries
        ],
        "topPages": [
            {"id": "index", "path": "wiki/docs/index.md", "type": "home"},
            {"id": "sources", "path": "wiki/docs/sources.md", "type": "sources"},
        ],
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the tGD multi-repo wiki (single-file HTML + Markdown)"
    )
    parser.add_argument("tgd_dir", help="$TGD_DIR path")
    parser.add_argument("--primary", help="Primary repo slug (defaults to first scan)")
    parser.add_argument("--dashboard-url", help="Dashboard URL to embed (applied to primary)")
    parser.add_argument(
        "--max-source-lines", type=int, default=DEFAULT_MAX_SOURCE_LINES,
        help=f"Max lines embedded per source file (default {DEFAULT_MAX_SOURCE_LINES})",
    )
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    tgd_dir = Path(args.tgd_dir).expanduser().resolve()
    if not tgd_dir.is_dir():
        sys.stderr.write(f"Error: TGD_DIR does not exist: {tgd_dir}\n")
        return 2

    repos = discover_repos(tgd_dir)
    if not repos:
        sys.stderr.write(
            f"Error: no repos with knowledge-graph.json under {tgd_dir}/.scans/\n"
            f"Run /tgd-map Step 4 (Understand-Anything) first.\n"
        )
        return 2

    primary_slug = pick_primary_slug(repos, args.primary)
    log(f"Discovered {len(repos)} repo(s). Primary: {primary_slug}", quiet=args.quiet)

    # Optional LLM-authored prose sidecar. Absent/broken → derivation fallback;
    # the generator never fails because prose is missing.
    prose_path = tgd_dir / "wiki" / "wiki-prose.json"
    all_prose: Dict[str, Any] = {}
    if prose_path.is_file():
        try:
            all_prose = (load_json(prose_path) or {}).get("repos") or {}
            log(f"Prose sidecar: {len(all_prose)} repo(s) annotated", quiet=args.quiet)
        except Exception as e:
            log(f"⚠️  Ignoring unreadable wiki-prose.json ({e}) — using derivation", quiet=False)

    docs_dir = tgd_dir / "wiki" / "docs"

    # Clear previous per-repo trees so removed repos don't leave stale pages
    repos_root = docs_dir / "repos"
    if repos_root.is_dir():
        import shutil
        shutil.rmtree(repos_root)

    generated_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    repo_summaries: List[Dict[str, Any]] = []
    dashboard_urls: Dict[str, Optional[str]] = {}
    models: List[WikiModel] = []

    for slug, scan_dir in repos:
        graph_path = scan_dir / ".understand-anything" / "knowledge-graph.json"
        try:
            graph = load_json(graph_path)
        except Exception as e:
            log(f"⚠️  Skipping {slug}: cannot load graph ({e})", quiet=False)
            continue

        log(
            f"[{slug}] graph: {len(graph.get('nodes') or [])} nodes, "
            f"{len(graph.get('edges') or [])} edges, "
            f"{len(graph.get('layers') or [])} layers, "
            f"{len(graph.get('tour') or [])} tour steps",
            quiet=args.quiet,
        )

        repo_path = infer_repo_path(scan_dir, graph.get("project") or {})
        repo_root = Path(repo_path).expanduser().resolve() if repo_path else Path("")
        this_dashboard = args.dashboard_url if slug == primary_slug else None
        dashboard_urls[slug] = this_dashboard

        model = compile_repo_model(
            graph=graph,
            repo_slug=slug,
            repo_path=repo_path,
            repo_root=repo_root,
            dashboard_url=this_dashboard,
            max_source_lines=args.max_source_lines,
        )
        # override generated_at so all repos share one timestamp
        model.generated_at = generated_at
        model.prose = all_prose.get(slug) or {}
        models.append(model)

        proj = model.project
        repo_summaries.append({
            "slug": slug,
            "name": proj.get("name") or slug,
            "description": proj.get("description") or "",
            "path": repo_path,
            "modules": [{"slug": m["slug"], "title": m["title"], "icon": m["icon"]}
                        for m in model.modules],
            "flows": [{"slug": f["slug"], "title": f["title"]} for f in model.flows],
            "module_count": len(model.modules),
            "flow_count": len(model.flows),
            "source_count": len(model.source_files),
            "is_primary": slug == primary_slug,
        })

    if not models:
        sys.stderr.write("Error: no repos could be compiled.\n")
        return 2

    report_prose_coverage(models, all_prose, quiet=args.quiet)

    # Markdown tree (agents + GitHub)
    for model in models:
        repo_docs_dir = docs_dir / "repos" / model.repo_slug
        log(f"Rendering markdown → {repo_docs_dir}", quiet=args.quiet)
        emit_repo_md(model, repo_docs_dir)
        write_json(repo_docs_dir / "manifest.json", build_repo_manifest(model))

    emit_top_md(docs_dir, repo_summaries, primary_slug, generated_at)
    write_json(
        docs_dir / "manifest.json",
        build_top_manifest(repo_summaries, primary_slug, generated_at, dashboard_urls),
    )

    # Single-file HTML wiki
    payload = build_payload(models, primary_slug, generated_at)
    dest = render_wiki_html(tgd_dir, payload, quiet=args.quiet)
    size_mb = dest.stat().st_size / (1024 * 1024)

    log("Done.", quiet=args.quiet)
    log(f"  Repos:    {len(models)}", quiet=args.quiet)
    log(f"  Primary:  {primary_slug}", quiet=args.quiet)
    log(f"  Wiki:     {dest} ({size_mb:.1f} MB — open directly in a browser)", quiet=args.quiet)
    log(f"  Docs:     {docs_dir}/index.md", quiet=args.quiet)
    log(f"  Manifest: {docs_dir}/manifest.json", quiet=args.quiet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
