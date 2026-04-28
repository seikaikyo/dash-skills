"""Tests for update_lookup.py."""

import update_lookup


class TestValidateFile:
    """Test file validation (same logic as create_lookup)."""

    def test_file_not_found(self):
        ok, msg = update_lookup.validate_file("/nonexistent/file.csv")
        assert not ok
        assert "not found" in msg.lower()

    def test_valid_csv(self, tmp_path):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        ok, msg = update_lookup.validate_file(str(f))
        assert ok

    def test_unexpected_extension(self, tmp_path):
        f = tmp_path / "test.xlsx"
        f.write_text("data")
        ok, msg = update_lookup.validate_file(str(f))
        assert not ok
        assert "unexpected" in msg.lower()


class TestUpdateLookup:
    """Test update API call handling."""

    def test_successful_update(self, tmp_path, monkeypatch, fake_credentials):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        mock_client = type("Mock", (), {
            "update_lookup_file": lambda self, **kw: {
                "status_code": 200,
                "body": {"errors": []},
            }
        })()
        monkeypatch.setattr(update_lookup, "get_client", lambda: mock_client)
        success, msg = update_lookup.update_lookup(str(f), "test.csv")
        assert success
        assert "updated" in msg.lower()

    def test_failed_update(self, tmp_path, monkeypatch, fake_credentials):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        mock_client = type("Mock", (), {
            "update_lookup_file": lambda self, **kw: {
                "status_code": 404,
                "body": {"errors": [{"message": "File not found"}]},
            }
        })()
        monkeypatch.setattr(update_lookup, "get_client", lambda: mock_client)
        success, msg = update_lookup.update_lookup(str(f), "missing.csv")
        assert not success
        assert "not found" in msg.lower()
