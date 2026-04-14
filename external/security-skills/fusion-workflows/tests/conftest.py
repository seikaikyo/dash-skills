"""
Shared test fixtures and helpers for security-skills tests.

All tests mock HTTP responses — no CrowdStrike API credentials needed.
"""

import os
import sys
import pytest

# Add scripts directory to path so tests can import the modules
SCRIPTS_DIR = os.path.join(
    os.path.dirname(__file__),
    "..",
    "skills",
    "fusion-workflows",
    "scripts",
)
sys.path.insert(0, os.path.abspath(SCRIPTS_DIR))

import cs_auth  # noqa: E402  # must be after sys.path.insert


@pytest.fixture(autouse=True)
def clean_env(monkeypatch):
    """Ensure no real credentials leak into tests."""
    monkeypatch.delenv("CS_CLIENT_ID", raising=False)
    monkeypatch.delenv("CS_CLIENT_SECRET", raising=False)
    monkeypatch.delenv("CS_BASE_URL", raising=False)
    # Point CS_ENV_FILE to a nonexistent path so load_env() won't walk up
    # and find a real .env file on the developer's machine.
    monkeypatch.setenv("CS_ENV_FILE", "/nonexistent/.env")
    cs_auth.reset_client()


@pytest.fixture
def fake_credentials(monkeypatch):
    """Set fake credentials for tests that need auth."""
    monkeypatch.setenv("CS_CLIENT_ID", "fake_client_id_1234567890abcdef")
    monkeypatch.setenv("CS_CLIENT_SECRET", "fake_secret_abcdef1234567890")
    monkeypatch.setenv("CS_BASE_URL", "https://api.crowdstrike.com")
