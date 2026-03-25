"""xAI Responses API backend for X search.

Uses Grok's x_search server-side tool to search X/Twitter
when only XAI_API_KEY is available (no X_BEARER_TOKEN).
"""

from __future__ import annotations

import os

import httpx

XAI_BASE = "https://api.x.ai/v1"
XAI_MODEL = "grok-4-fast"


def get_xai_key() -> str | None:
    """Return XAI_API_KEY if set, else None."""
    return os.environ.get("XAI_API_KEY")


def _responses_api(
    prompt: str,
    *,
    x_search_opts: dict | None = None,
) -> dict:
    """Call the xAI Responses API with x_search tool."""
    key = get_xai_key()
    if not key:
        msg = "XAI_API_KEY not found in environment"
        raise RuntimeError(msg)

    tool: dict = {"type": "x_search"}
    if x_search_opts:
        tool.update(x_search_opts)

    response = httpx.post(
        f"{XAI_BASE}/responses",
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        json={
            "model": XAI_MODEL,
            "input": [{"role": "user", "content": prompt}],
            "tools": [tool],
        },
        timeout=120,
    )

    if not response.is_success:
        msg = f"xAI API {response.status_code}: {response.text[:200]}"
        raise RuntimeError(msg)

    return response.json()


def _extract_text(data: dict) -> str:
    """Extract text content from xAI Responses API output."""
    for item in data.get("output", []):
        if item.get("type") == "message":
            for content in item.get("content", []):
                if content.get("type") == "output_text":
                    return content.get("text", "")
    return "(no results)"


def search(
    query: str,
    *,
    limit: int = 10,
    sort: str = "likes",
    since: str | None = None,
) -> str:
    """Search X via Grok's x_search tool. Returns formatted text."""
    time_hint = f" from the last {since}" if since else ""
    sort_hint = f" sorted by {sort}" if sort != "recent" else " most recent"

    prompt = (
        f"Search X for tweets about: {query}\n"
        f"Find up to {limit} results{time_hint},{sort_hint}.\n"
        "For each tweet, include:\n"
        "- @username\n"
        "- Tweet text (first 200 chars)\n"
        "- Engagement: likes, reposts, views\n"
        "- Tweet URL\n"
        "Format as a numbered list. Include engagement numbers."
    )

    data = _responses_api(prompt)
    text = _extract_text(data)

    usage = data.get("usage", {})
    tool_details = usage.get("server_side_tool_usage_details", {})
    x_calls = tool_details.get("x_search_calls", 0)

    return f"{text}\n\n[xAI backend | {x_calls} x_search call(s)]"


def thread(tweet_id: str) -> str:
    """Fetch a thread via Grok's x_search tool."""
    prompt = (
        f"Find and display the full conversation thread for tweet ID {tweet_id}. "
        "Show each tweet in order with @username, text, and engagement metrics."
    )
    data = _responses_api(prompt)
    return _extract_text(data)


def profile(username: str, *, count: int = 10) -> str:
    """Fetch recent tweets from a user via Grok's x_search tool."""
    username = username.lstrip("@")
    prompt = (
        f"Show the {count} most recent tweets from @{username}. "
        "For each tweet include: text, engagement metrics (likes, views), "
        "and tweet URL. Also include a brief profile summary at the top."
    )
    opts = {"allowed_x_handles": [username]}
    data = _responses_api(prompt, x_search_opts=opts)
    return _extract_text(data)


def tweet(tweet_id: str) -> str:
    """Fetch a single tweet via Grok's x_search tool."""
    prompt = (
        f"Find and display the tweet with ID {tweet_id}. "
        "Show: @username, full text, engagement metrics, and tweet URL."
    )
    data = _responses_api(prompt)
    return _extract_text(data)
