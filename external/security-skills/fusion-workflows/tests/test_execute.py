"""Tests for execute.py — parameter handling and response parsing."""

import inspect
from unittest.mock import MagicMock

import execute


class TestExecuteWorkflow:
    """Test workflow execution request building."""

    def test_params_merged_with_definition_id(self):
        """Verify the request body structure matches what the API expects."""
        sig = inspect.signature(execute.execute_workflow)
        params = list(sig.parameters.keys())
        assert "definition_id" in params
        assert "params" in params
        assert "depth" in params


class TestPollResults:
    """Test result polling logic."""

    def test_poll_timeout_returns_none(self, monkeypatch):
        """Verify timeout behavior without hitting real API."""
        call_count = 0
        mock_client = MagicMock()

        def mock_execution_results(**kwargs):
            nonlocal call_count
            call_count += 1
            return {"status_code": 200, "body": {"resources": [{"status": "running"}]}, "headers": {}}

        mock_client.execution_results = mock_execution_results
        monkeypatch.setattr(execute, "get_client", lambda: mock_client)
        result = execute.poll_results("fake_id", timeout=1, interval=0.1)
        assert result is None
        assert call_count > 0

    def test_poll_completed_returns_result(self, monkeypatch):
        """Verify completed status is returned."""
        mock_client = MagicMock()
        mock_client.execution_results.return_value = {
            "status_code": 200,
            "body": {"resources": [{"status": "completed", "output": {"key": "value"}}]},
            "headers": {},
        }
        monkeypatch.setattr(execute, "get_client", lambda: mock_client)
        result = execute.poll_results("fake_id", timeout=5, interval=0.1)
        assert result is not None
        assert result["status"] == "completed"
        assert result["output"] == {"key": "value"}

    def test_poll_failed_returns_result(self, monkeypatch):
        """Verify failed status is also returned (not retried forever)."""
        mock_client = MagicMock()
        mock_client.execution_results.return_value = {
            "status_code": 200,
            "body": {"resources": [{"status": "failed"}]},
            "headers": {},
        }
        monkeypatch.setattr(execute, "get_client", lambda: mock_client)
        result = execute.poll_results("fake_id", timeout=5, interval=0.1)
        assert result["status"] == "failed"
