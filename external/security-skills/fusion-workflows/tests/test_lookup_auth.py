"""Tests for lookup-files cs_auth.py (NGSIEM client)."""

import importlib
import os
import sys
from unittest.mock import patch, MagicMock

import pytest

# Save and swap the cs_auth module to load the lookup-files version
_orig_cs_auth = sys.modules.pop("cs_auth", None)

LOOKUP_SCRIPTS = os.path.abspath(os.path.join(
    os.path.dirname(__file__),
    "..",
    "plugins",
    "fusion-workflows",
    "skills",
    "lookup-files",
    "scripts",
))
sys.path.insert(0, LOOKUP_SCRIPTS)
import cs_auth as _lookup_auth  # noqa: E402
lookup_auth = _lookup_auth

# Restore original cs_auth so other tests aren't affected
sys.path.remove(LOOKUP_SCRIPTS)
if _orig_cs_auth is not None:
    sys.modules["cs_auth"] = _orig_cs_auth
else:
    sys.modules.pop("cs_auth", None)

# Keep lookup_auth accessible via its own module key
sys.modules["lookup_auth"] = lookup_auth


class TestGetNGSIEMClient:
    """Test that get_client() returns an NGSIEM instance."""

    @patch.object(lookup_auth, "NGSIEM")
    def test_returns_ngsiem_instance(self, mock_ngsiem, fake_credentials):
        lookup_auth.reset_client()
        mock_instance = MagicMock()
        mock_ngsiem.return_value = mock_instance
        client = lookup_auth.get_client()
        assert client is mock_instance
        mock_ngsiem.assert_called_once_with(
            client_id="fake_client_id_1234567890abcdef",
            client_secret="fake_secret_abcdef1234567890",
            base_url="https://api.crowdstrike.com",
        )

    @patch.object(lookup_auth, "NGSIEM")
    def test_returns_singleton(self, mock_ngsiem, fake_credentials):
        lookup_auth.reset_client()
        mock_ngsiem.return_value = MagicMock()
        first = lookup_auth.get_client()
        second = lookup_auth.get_client()
        assert first is second
        assert mock_ngsiem.call_count == 1

    @patch.object(lookup_auth, "NGSIEM")
    def test_reset_clears_singleton(self, mock_ngsiem, fake_credentials):
        lookup_auth.reset_client()
        mock_ngsiem.return_value = MagicMock()
        first = lookup_auth.get_client()
        lookup_auth.reset_client()
        mock_ngsiem.return_value = MagicMock()
        second = lookup_auth.get_client()
        assert first is not second
        assert mock_ngsiem.call_count == 2
