"""
Shared CrowdStrike authentication using FalconPy SDK (NGSIEM).

All other lookup-files scripts import from this module. Credentials are loaded
from a .env file (never hardcoded). Run directly to verify credentials:

    python cs_auth.py
"""

import os
import sys

from falconpy import NGSIEM

# Fix Windows console encoding
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ── .env loader ─────────────────────────────────────────────────────────────


def load_env(env_file=None):
    """
    Load key=value pairs from a .env file into os.environ.

    Resolution order for the .env path:
      1. Explicit env_file argument
      2. CS_ENV_FILE environment variable
      3. Walk upward from this script's directory to find '.env'
      4. Fall back to the project root
    """
    if env_file is None:
        env_file = os.environ.get("CS_ENV_FILE")

    if env_file is None:
        search = os.path.dirname(os.path.abspath(__file__))
        while True:
            candidate = os.path.join(search, ".env")
            if os.path.isfile(candidate):
                env_file = candidate
                break
            parent = os.path.dirname(search)
            if parent == search:
                break
            search = parent

    if env_file is None or not os.path.isfile(env_file):
        return  # No .env found; rely on existing environment variables

    with open(env_file, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            os.environ.setdefault(key, value)


# ── Credentials ─────────────────────────────────────────────────────────────


def get_credentials():
    """Return (client_id, client_secret, base_url) from environment."""
    load_env()
    client_id = os.environ.get("CS_CLIENT_ID", "")
    client_secret = os.environ.get("CS_CLIENT_SECRET", "")
    base_url = os.environ.get("CS_BASE_URL", "https://api.crowdstrike.com")
    if not client_id or not client_secret:
        print(
            "ERROR: CS_CLIENT_ID and CS_CLIENT_SECRET must be set "
            "in .env or environment.",
            file=sys.stderr,
        )
        sys.exit(1)
    return client_id, client_secret, base_url.rstrip("/")


# ── FalconPy client ────────────────────────────────────────────────────────

_client = None  # pylint: disable=invalid-name


def get_client():
    """Return a shared FalconPy NGSIEM client, creating it on first use."""
    global _client  # pylint: disable=global-statement
    if _client is None:
        client_id, client_secret, base_url = get_credentials()
        _client = NGSIEM(
            client_id=client_id,
            client_secret=client_secret,
            base_url=base_url,
        )
    return _client


def reset_client():
    """Reset the shared client (useful for testing)."""
    global _client  # pylint: disable=global-statement
    _client = None


# ── Self-test ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("CrowdStrike Auth — self-test (FalconPy NGSIEM)")
    print("─" * 40)
    cid, csec, burl = get_credentials()
    print(f"  Base URL  : {burl}")
    print(f"  Client ID : {cid[:8]}...{cid[-4:]}")
    print(f"  Secret    : {'*' * 8}...{csec[-4:]}")
    print()
    try:
        ngsiem_client = get_client()
        if ngsiem_client.token_expired():
            print("  Authentication FAILED: could not obtain token", file=sys.stderr)
            sys.exit(1)
        print("  Authentication successful (FalconPy NGSIEM client)")
    except Exception as e:  # pylint: disable=broad-exception-caught
        print(f"\n  Authentication FAILED: {e}", file=sys.stderr)
        sys.exit(1)
