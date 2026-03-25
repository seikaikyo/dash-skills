#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27"]
# ///
"""x-search -- CLI for X/Twitter research.

Commands:
  search <query> [options]    Search recent tweets
  thread <tweet_id>           Fetch full conversation thread
  profile <username>          Recent tweets from a user
  tweet <tweet_id>            Fetch a single tweet
  watchlist                   Show watchlist
  watchlist add <user>        Add user to watchlist
  watchlist remove <user>     Remove user from watchlist
  watchlist check             Check recent tweets from all watchlist accounts
  cache clear                 Clear search cache
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow importing sibling modules when run via uv
sys.path.insert(0, str(Path(__file__).resolve().parent))

import os
from datetime import UTC

import x_api as api
import x_cache as cache
import x_format as fmt
import x_xai as xai


def _use_xai() -> bool:
    """True if only XAI_API_KEY is available (no X_BEARER_TOKEN)."""
    return not os.environ.get("X_BEARER_TOKEN") and bool(os.environ.get("XAI_API_KEY"))


SKILL_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = SKILL_DIR / "data"
WATCHLIST_PATH = DATA_DIR / "watchlist.json"


def _load_watchlist() -> dict:
    if not WATCHLIST_PATH.exists():
        return {"accounts": []}
    return json.loads(WATCHLIST_PATH.read_text())


def _save_watchlist(wl: dict) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    WATCHLIST_PATH.write_text(json.dumps(wl, indent=2) + "\n")


def cmd_search(args: argparse.Namespace) -> None:
    """Search recent tweets."""
    query = args.query
    limit = args.limit

    if args.quick:
        limit = min(limit, 10)

    if args.from_user and "from:" not in query.lower():
        query += f" from:{args.from_user.lstrip('@')}"

    if _use_xai():
        print(xai.search(query, limit=limit, sort=args.sort, since=args.since))
        return

    pages = args.pages
    if args.quick:
        pages = 1

    if "is:retweet" not in query:
        query += " -is:retweet"
    if (args.quick or args.no_replies) and "is:reply" not in query:
        query += " -is:reply"

    cache_ttl = 3600 if args.quick else 900
    cache_params = f"sort={args.sort}&pages={pages}&since={args.since or '7d'}"

    cached = cache.get(query, cache_params, cache_ttl)
    if cached is not None:
        tweets = cached
        print(f"(cached -- {len(tweets)} tweets)", file=sys.stderr)
    else:
        sort_order = "recency" if args.sort == "recent" else "relevancy"
        tweets = api.search(
            query,
            pages=pages,
            sort_order=sort_order,
            since=args.since,
        )
        cache.set(query, cache_params, tweets)

    raw_count = len(tweets)

    if args.min_likes > 0 or args.min_impressions > 0:
        tweets = api.filter_engagement(
            tweets,
            min_likes=args.min_likes or None,
            min_impressions=args.min_impressions or None,
        )

    if args.quality:
        tweets = api.filter_engagement(tweets, min_likes=10)

    if args.sort != "recent":
        tweets = api.sort_by(tweets, args.sort)

    tweets = api.dedupe(tweets)

    if args.json:
        print(json.dumps(tweets[:limit], indent=2))
    elif args.markdown:
        print(fmt.format_research_markdown(query, tweets, queries=[query]))
    else:
        print(fmt.format_results_terminal(tweets, query=query, limit=limit))

    if args.save:
        import re
        from datetime import datetime

        slug = re.sub(r"[^a-zA-Z0-9]+", "-", query).strip("-")[:40].lower()
        date = datetime.now(tz=UTC).strftime("%Y-%m-%d")
        save_dir = Path.home() / "x-research-output"
        save_dir.mkdir(parents=True, exist_ok=True)
        save_path = save_dir / f"x-research-{slug}-{date}.md"
        md = fmt.format_research_markdown(query, tweets, queries=[query])
        save_path.write_text(md)
        print(f"\nSaved to {save_path}", file=sys.stderr)

    cost = f"{raw_count * 0.005:.2f}"
    if args.quick:
        print(
            f"\nquick mode | {raw_count} tweets read (~${cost})",
            file=sys.stderr,
        )
    else:
        print(f"\n{raw_count} tweets read | est. cost ~${cost}", file=sys.stderr)

    filtered = f" -> {len(tweets)} after filters" if raw_count != len(tweets) else ""
    since_label = f" | since {args.since}" if args.since else ""
    print(
        f"{raw_count} tweets{filtered}"
        f" | sorted by {args.sort} | {pages} page(s){since_label}",
        file=sys.stderr,
    )


def cmd_thread(args: argparse.Namespace) -> None:
    """Fetch full conversation thread."""
    if _use_xai():
        print(xai.thread(args.tweet_id))
        return

    tweets = api.thread(args.tweet_id, pages=min(args.pages, 5))
    if not tweets:
        print("No tweets found in thread.")
        return

    print(f"Thread ({len(tweets)} tweets)\n")
    for t in tweets:
        print(fmt.format_tweet_terminal(t, full=True))
        print()


def cmd_profile(args: argparse.Namespace) -> None:
    """Recent tweets from a user."""
    username = args.username.lstrip("@")

    if _use_xai():
        print(xai.profile(username, count=args.count))
        return

    user, tweets = api.profile(
        username,
        count=args.count,
        include_replies=args.replies,
    )

    if args.json:
        print(json.dumps({"user": user, "tweets": tweets}, indent=2))
    else:
        print(fmt.format_profile_terminal(user, tweets))


def cmd_tweet(args: argparse.Namespace) -> None:
    """Fetch a single tweet."""
    if _use_xai():
        print(xai.tweet(args.tweet_id))
        return

    tweet = api.get_tweet(args.tweet_id)
    if not tweet:
        print("Tweet not found.")
        return

    if args.json:
        print(json.dumps(tweet, indent=2))
    else:
        print(fmt.format_tweet_terminal(tweet, full=True))


def cmd_watchlist(args: argparse.Namespace) -> None:
    """Manage watchlist."""
    wl = _load_watchlist()
    sub = args.watchlist_action

    if sub == "add":
        username = args.watchlist_user.lstrip("@")
        existing = [
            a for a in wl["accounts"] if a["username"].lower() == username.lower()
        ]
        if existing:
            print(f"@{username} already on watchlist.")
            return
        from datetime import datetime

        entry = {
            "username": username,
            "addedAt": datetime.now(tz=UTC).isoformat(),
        }
        if args.watchlist_note:
            entry["note"] = " ".join(args.watchlist_note)
        wl["accounts"].append(entry)
        _save_watchlist(wl)
        note = f" ({entry.get('note', '')})" if entry.get("note") else ""
        print(f"Added @{username} to watchlist.{note}")
        return

    if sub in ("remove", "rm"):
        username = args.watchlist_user.lstrip("@")
        before = len(wl["accounts"])
        wl["accounts"] = [
            a for a in wl["accounts"] if a["username"].lower() != username.lower()
        ]
        _save_watchlist(wl)
        if len(wl["accounts"]) < before:
            print(f"Removed @{username} from watchlist.")
        else:
            print(f"@{username} not found on watchlist.")
        return

    if sub == "check":
        if not wl["accounts"]:
            print("Watchlist is empty. Add accounts with: watchlist add <user>")
            return
        print(f"Checking {len(wl['accounts'])} watchlist accounts...\n")
        for acct in wl["accounts"]:
            note = f" ({acct['note']})" if acct.get("note") else ""
            print(f"\n--- @{acct['username']}{note} ---")
            try:
                if _use_xai():
                    print(xai.profile(acct["username"], count=3))
                else:
                    _, tweets = api.profile(acct["username"], count=5)
                    if not tweets:
                        print("  No recent tweets.")
                    else:
                        for t in tweets[:3]:
                            print(fmt.format_tweet_terminal(t))
                            print()
            except RuntimeError as exc:
                print(
                    f"  Error checking @{acct['username']}: {exc}",
                    file=sys.stderr,
                )
        return

    if not wl["accounts"]:
        print("Watchlist is empty. Add accounts with: watchlist add <user>")
        return
    print(f"Watchlist ({len(wl['accounts'])} accounts)\n")
    for acct in wl["accounts"]:
        note = f" -- {acct['note']}" if acct.get("note") else ""
        added = acct.get("addedAt", "?").split("T")[0]
        print(f"  @{acct['username']}{note} (added {added})")


def cmd_cache(args: argparse.Namespace) -> None:
    """Manage cache."""
    if args.cache_action == "clear":
        removed = cache.clear()
        print(f"Cleared {removed} cached entries.")
    else:
        removed = cache.prune()
        print(f"Pruned {removed} expired entries.")


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser."""
    parser = argparse.ArgumentParser(
        prog="x-search",
        description="X/Twitter research CLI",
    )
    sub = parser.add_subparsers(dest="command")

    # search
    sp = sub.add_parser("search", aliases=["s"], help="Search recent tweets")
    sp.add_argument("query", help="Search query")
    sp.add_argument(
        "--sort",
        default="likes",
        choices=["likes", "impressions", "retweets", "recent"],
    )
    sp.add_argument("--since", help="Time filter: 1h, 3h, 12h, 1d, 7d")
    sp.add_argument("--min-likes", type=int, default=0)
    sp.add_argument("--min-impressions", type=int, default=0)
    sp.add_argument("--pages", type=int, default=1)
    sp.add_argument("--limit", type=int, default=15)
    sp.add_argument("--quick", action="store_true")
    sp.add_argument("--from-user", metavar="USER", dest="from_user")
    sp.add_argument("--quality", action="store_true")
    sp.add_argument("--no-replies", action="store_true")
    sp.add_argument("--save", action="store_true")
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--markdown", action="store_true")

    # thread
    sp = sub.add_parser("thread", aliases=["t"], help="Fetch conversation")
    sp.add_argument("tweet_id", help="Root tweet ID")
    sp.add_argument("--pages", type=int, default=2)

    # profile
    sp = sub.add_parser("profile", aliases=["p"], help="User profile")
    sp.add_argument("username", help="X username")
    sp.add_argument("--count", type=int, default=20)
    sp.add_argument("--replies", action="store_true")
    sp.add_argument("--json", action="store_true")

    # tweet
    sp = sub.add_parser("tweet", help="Fetch single tweet")
    sp.add_argument("tweet_id", help="Tweet ID")
    sp.add_argument("--json", action="store_true")

    # watchlist
    sp = sub.add_parser("watchlist", aliases=["wl"], help="Manage watchlist")
    sp.add_argument(
        "watchlist_action",
        nargs="?",
        default="show",
        choices=["show", "add", "remove", "rm", "check"],
    )
    sp.add_argument("watchlist_user", nargs="?")
    sp.add_argument("watchlist_note", nargs="*")

    # cache
    sp = sub.add_parser("cache", help="Manage cache")
    sp.add_argument(
        "cache_action",
        nargs="?",
        default="prune",
        choices=["clear", "prune"],
    )

    return parser


def main() -> None:
    """Entry point."""
    parser = build_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    commands = {
        "search": cmd_search,
        "s": cmd_search,
        "thread": cmd_thread,
        "t": cmd_thread,
        "profile": cmd_profile,
        "p": cmd_profile,
        "tweet": cmd_tweet,
        "watchlist": cmd_watchlist,
        "wl": cmd_watchlist,
        "cache": cmd_cache,
    }

    handler = commands.get(args.command)
    if handler:
        handler(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
