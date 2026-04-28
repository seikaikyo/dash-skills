"""Tests for delete_lookup.py."""

import json

import delete_lookup


class TestDeleteConfirmation:
    """Test confirmation safety logic."""

    def test_json_without_confirm_exits(self, capsys):
        """--json mode requires --confirm to prevent silent deletes."""
        try:
            import sys
            sys.argv = ["delete_lookup.py", "--name", "test.csv", "--json"]
            delete_lookup.main()
            assert False, "Should have called sys.exit"
        except SystemExit as e:
            assert e.code == 1
        output = json.loads(capsys.readouterr().out)
        assert output["success"] is False
        assert "--confirm" in output["error"]


class TestDeleteLookup:
    """Test delete API call handling."""

    def test_successful_delete(self, monkeypatch, fake_credentials):
        mock_client = type("Mock", (), {
            "delete_lookup_file": lambda self, **kw: {
                "status_code": 200,
                "body": {"errors": []},
            }
        })()
        monkeypatch.setattr(delete_lookup, "get_client", lambda: mock_client)
        success, msg = delete_lookup.delete_lookup("test.csv")
        assert success
        assert "deleted" in msg.lower()

    def test_failed_delete(self, monkeypatch, fake_credentials):
        mock_client = type("Mock", (), {
            "delete_lookup_file": lambda self, **kw: {
                "status_code": 404,
                "body": {"errors": [{"message": "File not found"}]},
            }
        })()
        monkeypatch.setattr(delete_lookup, "get_client", lambda: mock_client)
        success, msg = delete_lookup.delete_lookup("missing.csv")
        assert not success
        assert "not found" in msg.lower()
