"""File-based cache for X API results.

Avoids re-fetching identical queries within a TTL window.
"""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path

CACHE_DIR = Path(__file__).resolve().parent.parent / "data" / "cache"
DEFAULT_TTL_S = 15 * 60


def _ensure_dir() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def _cache_key(query: str, params: str = "") -> str:
    return hashlib.md5(
        f"{query}|{params}".encode(),
        usedforsecurity=False,
    ).hexdigest()[:12]


def get(
    query: str,
    params: str = "",
    ttl_s: float = DEFAULT_TTL_S,
) -> list[dict] | None:
    """Return cached tweets or None if expired/missing."""
    _ensure_dir()
    path = CACHE_DIR / f"{_cache_key(query, params)}.json"
    if not path.exists():
        return None

    try:
        entry = json.loads(path.read_text())
        if time.time() - entry["timestamp"] > ttl_s:
            path.unlink(missing_ok=True)
            return None
        return entry["tweets"]
    except (json.JSONDecodeError, KeyError):
        return None


def set(  # noqa: A001
    query: str,
    params: str = "",
    tweets: list[dict] | None = None,
) -> None:
    """Cache tweet results."""
    _ensure_dir()
    path = CACHE_DIR / f"{_cache_key(query, params)}.json"
    entry = {
        "query": query,
        "params": params,
        "timestamp": time.time(),
        "tweets": tweets or [],
    }
    path.write_text(json.dumps(entry, indent=2))


def prune(ttl_s: float = DEFAULT_TTL_S) -> int:
    """Remove expired cache entries. Returns count removed."""
    _ensure_dir()
    removed = 0
    for path in CACHE_DIR.glob("*.json"):
        if time.time() - path.stat().st_mtime > ttl_s:
            path.unlink(missing_ok=True)
            removed += 1
    return removed


def clear() -> int:
    """Remove all cache entries. Returns count removed."""
    _ensure_dir()
    files = list(CACHE_DIR.glob("*.json"))
    for path in files:
        path.unlink(missing_ok=True)
    return len(files)
