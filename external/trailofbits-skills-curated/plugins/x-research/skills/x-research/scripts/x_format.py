"""Format tweets for terminal or markdown output."""

from __future__ import annotations

import time as _time
from datetime import UTC, datetime
from urllib.parse import urlparse


def _compact(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def _time_ago(date_str: str) -> str:
    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except ValueError:
        return "?"
    diff = _time.time() - dt.timestamp()
    mins = int(diff // 60)
    if mins < 60:
        return f"{mins}m"
    hours = mins // 60
    if hours < 24:
        return f"{hours}h"
    return f"{hours // 24}d"


def _clean_text(text: str) -> str:
    """Remove t.co links from tweet text."""
    import re

    return re.sub(r"https://t\.co/\S+", "", text).strip()


def format_tweet_terminal(
    tweet: dict,
    index: int | None = None,
    *,
    full: bool = False,
) -> str:
    """Format a single tweet for terminal display."""
    prefix = f"{index + 1}. " if index is not None else ""
    m = tweet["metrics"]
    engagement = f"{_compact(m['likes'])}L {_compact(m['impressions'])}I"
    age = _time_ago(tweet["created_at"])

    text = tweet["text"]
    if not full and len(text) > 200:
        text = text[:197] + "..."
    text = _clean_text(text)

    out = f"{prefix}@{tweet['username']} ({engagement} | {age})\n{text}"

    if tweet.get("urls"):
        out += f"\n  {tweet['urls'][0]}"
    out += f"\n  {tweet['tweet_url']}"

    return out


def format_results_terminal(
    tweets: list[dict],
    query: str = "",
    limit: int = 15,
) -> str:
    """Format a list of tweets for terminal display."""
    shown = tweets[:limit]

    parts = []
    if query:
        parts.append(f'"{query}" -- {len(tweets)} results\n')

    for i, t in enumerate(shown):
        parts.append(format_tweet_terminal(t, i))

    if len(tweets) > limit:
        parts.append(f"\n... +{len(tweets) - limit} more")

    return "\n\n".join(parts)


def format_tweet_markdown(tweet: dict) -> str:
    """Format a single tweet for markdown research docs."""
    m = tweet["metrics"]
    engagement = f"{m['likes']}L {m['impressions']}I"
    text = _clean_text(tweet["text"]).replace("\n", "\n  > ")

    out = (
        f"- **@{tweet['username']}** ({engagement})"
        f" [Tweet]({tweet['tweet_url']})\n  > {text}"
    )

    if tweet.get("urls"):
        links = ", ".join(f"[{urlparse(u).hostname}]({u})" for u in tweet["urls"])
        out += f"\n  Links: {links}"

    return out


def format_research_markdown(
    query: str,
    tweets: list[dict],
    queries: list[str] | None = None,
) -> str:
    """Format results as a markdown research document."""
    date = datetime.now(tz=UTC).strftime("%Y-%m-%d")

    lines = [
        f"# X Research: {query}\n",
        f"**Date:** {date}",
        f"**Tweets found:** {len(tweets)}\n",
        "## Top Results (by engagement)\n",
    ]

    for t in tweets[:30]:
        lines.append(format_tweet_markdown(t))
        lines.append("")

    lines.append("---\n")
    lines.append("## Research Metadata\n")
    lines.append(f"- **Query:** {query}")
    lines.append(f"- **Date:** {date}")
    lines.append(f"- **Tweets scanned:** {len(tweets)}")
    lines.append(f"- **Est. cost:** ~${len(tweets) * 0.005:.2f}")

    if queries:
        lines.append("- **Search queries:**")
        for q in queries:
            lines.append(f"  - `{q}`")

    return "\n".join(lines) + "\n"


def format_profile_terminal(user: dict, tweets: list[dict]) -> str:
    """Format a user profile for terminal display."""
    m = user.get("public_metrics", {})
    followers = _compact(m.get("followers_count", 0))
    tweet_count = _compact(m.get("tweet_count", 0))

    lines = [
        f"@{user.get('username', '?')} -- {user.get('name', '?')}",
        f"{followers} followers | {tweet_count} tweets",
    ]

    desc = user.get("description", "")
    if desc:
        lines.append(desc[:150])

    lines.append("\nRecent:\n")

    for i, t in enumerate(tweets[:10]):
        lines.append(format_tweet_terminal(t, i))
        lines.append("")

    return "\n".join(lines)
