"""X API wrapper -- search, threads, profiles, single tweets.

Uses Bearer token from env: X_BEARER_TOKEN or XAI_API_KEY.
"""

from __future__ import annotations

import os
import re
import time
from datetime import UTC, datetime
from urllib.parse import quote

import httpx

BASE = "https://api.x.com/2"
RATE_DELAY_S = 0.35
FIELDS = (
    "tweet.fields=created_at,public_metrics,author_id,conversation_id,entities"
    "&expansions=author_id"
    "&user.fields=username,name,public_metrics"
)


def get_token() -> str:
    """Get bearer token from X_BEARER_TOKEN or XAI_API_KEY env var."""
    token = os.environ.get("X_BEARER_TOKEN") or os.environ.get("XAI_API_KEY")
    if not token:
        msg = "X_BEARER_TOKEN or XAI_API_KEY not found in environment"
        raise RuntimeError(msg)
    return token


def _parse_tweets(raw: dict) -> list[dict]:
    """Parse API response into tweet dicts."""
    data = raw.get("data")
    if not data:
        return []

    users: dict[str, dict] = {}
    for u in raw.get("includes", {}).get("users", []):
        users[u["id"]] = u

    tweets = []
    for t in data:
        u = users.get(t.get("author_id", ""), {})
        m = t.get("public_metrics", {})
        entities = t.get("entities", {})
        username = u.get("username", "?")

        tweets.append(
            {
                "id": t["id"],
                "text": t.get("text", ""),
                "author_id": t.get("author_id", ""),
                "username": username,
                "name": u.get("name", "?"),
                "created_at": t.get("created_at", ""),
                "conversation_id": t.get("conversation_id", ""),
                "metrics": {
                    "likes": m.get("like_count", 0),
                    "retweets": m.get("retweet_count", 0),
                    "replies": m.get("reply_count", 0),
                    "quotes": m.get("quote_count", 0),
                    "impressions": m.get("impression_count", 0),
                    "bookmarks": m.get("bookmark_count", 0),
                },
                "urls": [
                    e["expanded_url"]
                    for e in entities.get("urls", [])
                    if e.get("expanded_url")
                ],
                "mentions": [
                    e["username"]
                    for e in entities.get("mentions", [])
                    if e.get("username")
                ],
                "hashtags": [
                    h["tag"] for h in entities.get("hashtags", []) if h.get("tag")
                ],
                "tweet_url": f"https://x.com/{username}/status/{t['id']}",
            }
        )

    return tweets


def _parse_since(since: str) -> str | None:
    """Parse '1h', '3d', etc. into ISO 8601 timestamp."""
    match = re.match(r"^(\d+)(m|h|d)$", since)
    if match:
        num = int(match.group(1))
        unit = match.group(2)
        seconds = num * {"m": 60, "h": 3600, "d": 86400}[unit]
        start = datetime.now(tz=UTC).timestamp() - seconds
        return datetime.fromtimestamp(start, tz=UTC).isoformat()

    if "T" in since or "-" in since:
        try:
            return datetime.fromisoformat(since).isoformat()
        except ValueError:
            return None

    return None


def _api_get(url: str) -> dict:
    """Make authenticated GET request to X API."""
    token = get_token()
    response = httpx.get(
        url,
        headers={"Authorization": f"Bearer {token}"},
        timeout=30,
    )

    if response.status_code == 429:
        reset = response.headers.get("x-rate-limit-reset")
        wait = max(int(reset) - int(time.time()), 1) if reset else 60
        msg = f"Rate limited. Resets in {wait}s"
        raise RuntimeError(msg)

    if not response.is_success:
        msg = f"X API {response.status_code}: {response.text[:200]}"
        raise RuntimeError(msg)

    return response.json()


def search(
    query: str,
    *,
    max_results: int = 100,
    pages: int = 1,
    sort_order: str = "relevancy",
    since: str | None = None,
) -> list[dict]:
    """Search recent tweets (last 7 days)."""
    max_results = max(min(max_results, 100), 10)
    encoded = quote(query, safe="")

    time_filter = ""
    if since:
        start_time = _parse_since(since)
        if start_time:
            time_filter = f"&start_time={start_time}"

    all_tweets: list[dict] = []
    next_token: str | None = None

    for page in range(pages):
        pagination = f"&pagination_token={next_token}" if next_token else ""
        url = (
            f"{BASE}/tweets/search/recent?query={encoded}"
            f"&max_results={max_results}&{FIELDS}"
            f"&sort_order={sort_order}{time_filter}{pagination}"
        )

        raw = _api_get(url)
        all_tweets.extend(_parse_tweets(raw))

        next_token = raw.get("meta", {}).get("next_token")
        if not next_token:
            break
        if page < pages - 1:
            time.sleep(RATE_DELAY_S)

    return all_tweets


def thread(conversation_id: str, *, pages: int = 2) -> list[dict]:
    """Fetch full conversation thread by root tweet ID."""
    query = f"conversation_id:{conversation_id}"
    tweets = search(query, pages=pages, sort_order="recency")

    try:
        raw = _api_get(f"{BASE}/tweets/{conversation_id}?{FIELDS}")
        if raw.get("data") and not isinstance(raw["data"], list):
            root = _parse_tweets({**raw, "data": [raw["data"]]})
            if root:
                tweets.insert(0, root[0])
    except RuntimeError:
        pass

    return tweets


def profile(
    username: str,
    *,
    count: int = 20,
    include_replies: bool = False,
) -> tuple[dict, list[dict]]:
    """Get recent tweets from a specific user."""
    user_url = (
        f"{BASE}/users/by/username/{username}"
        "?user.fields=public_metrics,description,created_at"
    )
    user_data = _api_get(user_url)

    if not user_data.get("data"):
        msg = f"User @{username} not found"
        raise RuntimeError(msg)

    user = user_data["data"]
    time.sleep(RATE_DELAY_S)

    reply_filter = "" if include_replies else " -is:reply"
    query = f"from:{username} -is:retweet{reply_filter}"
    tweets = search(
        query,
        max_results=min(count, 100),
        sort_order="recency",
    )

    return user, tweets


def get_tweet(tweet_id: str) -> dict | None:
    """Fetch a single tweet by ID."""
    raw = _api_get(f"{BASE}/tweets/{tweet_id}?{FIELDS}")
    if raw.get("data") and not isinstance(raw["data"], list):
        parsed = _parse_tweets({**raw, "data": [raw["data"]]})
        return parsed[0] if parsed else None
    return None


def sort_by(
    tweets: list[dict],
    metric: str = "likes",
) -> list[dict]:
    """Sort tweets by engagement metric."""
    return sorted(
        tweets,
        key=lambda t: t["metrics"].get(metric, 0),
        reverse=True,
    )


def filter_engagement(
    tweets: list[dict],
    *,
    min_likes: int | None = None,
    min_impressions: int | None = None,
) -> list[dict]:
    """Filter tweets by minimum engagement."""
    result = []
    for t in tweets:
        if min_likes and t["metrics"]["likes"] < min_likes:
            continue
        if min_impressions and t["metrics"]["impressions"] < min_impressions:
            continue
        result.append(t)
    return result


def dedupe(tweets: list[dict]) -> list[dict]:
    """Deduplicate tweets by ID."""
    seen: set[str] = set()
    result = []
    for t in tweets:
        if t["id"] not in seen:
            seen.add(t["id"])
            result.append(t)
    return result
