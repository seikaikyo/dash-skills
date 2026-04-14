"""Tests for cs_auth.py — credential loading and FalconPy client."""

import os
from unittest.mock import patch, MagicMock

import pytest

import cs_auth


class TestLoadEnv:
    """Test .env file loading."""

    def test_load_from_explicit_path(self, tmp_path):
        env_file = tmp_path / ".env"
        env_file.write_text('CS_CLIENT_ID=from_file\nCS_CLIENT_SECRET=secret_file\n')
        cs_auth.load_env(str(env_file))
        assert os.environ.get("CS_CLIENT_ID") == "from_file"

    def test_skips_comments_and_blanks(self, tmp_path):
        env_file = tmp_path / ".env"
        env_file.write_text('# comment\n\nCS_BASE_URL=https://test.com\n')
        cs_auth.load_env(str(env_file))
        assert os.environ.get("CS_BASE_URL") == "https://test.com"

    def test_strips_quotes(self, tmp_path):
        env_file = tmp_path / ".env"
        env_file.write_text('CS_CLIENT_ID="quoted_value"\n')
        cs_auth.load_env(str(env_file))
        assert os.environ.get("CS_CLIENT_ID") == "quoted_value"

    def test_does_not_override_existing(self, tmp_path, monkeypatch):
        monkeypatch.setenv("CS_CLIENT_ID", "existing")
        env_file = tmp_path / ".env"
        env_file.write_text("CS_CLIENT_ID=from_file\n")
        cs_auth.load_env(str(env_file))
        assert os.environ["CS_CLIENT_ID"] == "existing"

    def test_no_env_file_is_noop(self):
        cs_auth.load_env("/nonexistent/path/.env")


class TestGetCredentials:
    """Test credential retrieval."""

    def test_returns_credentials(self, fake_credentials):
        cid, csec, burl = cs_auth.get_credentials()
        assert cid == "fake_client_id_1234567890abcdef"
        assert csec == "fake_secret_abcdef1234567890"
        assert burl == "https://api.crowdstrike.com"

    def test_strips_trailing_slash(self, monkeypatch):
        monkeypatch.setenv("CS_CLIENT_ID", "test")
        monkeypatch.setenv("CS_CLIENT_SECRET", "test")
        monkeypatch.setenv("CS_BASE_URL", "https://api.crowdstrike.com/")
        _, _, burl = cs_auth.get_credentials()
        assert not burl.endswith("/")

    def test_exits_without_credentials(self):
        with pytest.raises(SystemExit):
            cs_auth.get_credentials()


class TestGetClient:
    """Test FalconPy Workflows client creation."""

    @patch("cs_auth.Workflows")
    def test_returns_workflows_instance(self, mock_workflows, fake_credentials):
        mock_instance = MagicMock()
        mock_workflows.return_value = mock_instance
        client = cs_auth.get_client()
        assert client is mock_instance
        mock_workflows.assert_called_once_with(
            client_id="fake_client_id_1234567890abcdef",
            client_secret="fake_secret_abcdef1234567890",
            base_url="https://api.crowdstrike.com",
        )

    @patch("cs_auth.Workflows")
    def test_returns_singleton(self, mock_workflows, fake_credentials):
        mock_workflows.return_value = MagicMock()
        first = cs_auth.get_client()
        second = cs_auth.get_client()
        assert first is second
        assert mock_workflows.call_count == 1

    @patch("cs_auth.Workflows")
    def test_reset_clears_singleton(self, mock_workflows, fake_credentials):
        mock_workflows.return_value = MagicMock()
        first = cs_auth.get_client()
        cs_auth.reset_client()
        mock_workflows.return_value = MagicMock()
        second = cs_auth.get_client()
        assert first is not second
        assert mock_workflows.call_count == 2
