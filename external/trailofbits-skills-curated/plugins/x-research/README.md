# x-research

X/Twitter research agent for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Search, filter, monitor -- all from the terminal.

## Install

```bash
/plugin install trailofbits/skills-curated/plugins/x-research
```

## Prerequisites

- **X API Bearer Token** -- get one from the [X Developer Portal](https://developer.x.com)
- **Python 3.11+** and **uv** -- https://docs.astral.sh/uv/
- Set `X_BEARER_TOKEN` or `XAI_API_KEY` environment variable

## What It Covers

- **Search** with engagement sorting, time filtering, noise removal
- **Quick mode** for cheap, targeted lookups (~$0.50/search)
- **Profiles** -- recent tweets from any user
- **Threads** -- full conversation by root tweet ID
- **Watchlists** for monitoring accounts
- **Cache** to avoid repeat API charges (15min TTL)
- **Agentic research loop** -- decompose questions, search iteratively, follow threads, synthesize

## Usage

Natural language (just talk to Claude):
- "What are people saying about Claude Code?"
- "Search X for React Server Components"
- "Check what @anthropic posted recently"

CLI (via the agent):
```bash
uv run scripts/x_search.py search "your query" --sort likes --limit 10
uv run scripts/x_search.py search "AI agents" --quick
uv run scripts/x_search.py profile anthropic
uv run scripts/x_search.py thread TWEET_ID
uv run scripts/x_search.py watchlist check
```

## Cost

X API uses pay-per-use pricing ($0.005/post read). Quick mode keeps costs under ~$0.50/search. Cache prevents duplicate charges. 24-hour deduplication at the API level means re-running searches within a day costs less.

## Credits

Imported from [rohunvora/x-research-skill](https://github.com/rohunvora/x-research-skill). Original TypeScript implementation by rohunvora, converted to Python for this plugin. License: MIT.
