"""Tests for create_lookup.py."""

import create_lookup


class TestValidateFile:
    """Test file validation logic."""

    def test_file_not_found(self):
        ok, msg = create_lookup.validate_file("/nonexistent/file.csv")
        assert not ok
        assert "not found" in msg.lower()

    def test_valid_csv(self, tmp_path):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        ok, msg = create_lookup.validate_file(str(f))
        assert ok

    def test_valid_json(self, tmp_path):
        f = tmp_path / "test.json"
        f.write_text('[{"a": 1}]')
        ok, msg = create_lookup.validate_file(str(f))
        assert ok

    def test_valid_txt(self, tmp_path):
        f = tmp_path / "test.txt"
        f.write_text("data")
        ok, msg = create_lookup.validate_file(str(f))
        assert ok

    def test_unexpected_extension(self, tmp_path):
        f = tmp_path / "test.xlsx"
        f.write_text("data")
        ok, msg = create_lookup.validate_file(str(f))
        assert not ok
        assert "unexpected" in msg.lower()


class TestCreateLookup:
    """Test create API call handling."""

    def test_successful_create(self, tmp_path, monkeypatch, fake_credentials):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        mock_client = type("Mock", (), {
            "create_lookup_file": lambda self, **kw: {
                "status_code": 200,
                "body": {"errors": []},
            }
        })()
        monkeypatch.setattr(create_lookup, "get_client", lambda: mock_client)
        success, msg = create_lookup.create_lookup(str(f))
        assert success
        assert "created" in msg.lower()

    def test_failed_create(self, tmp_path, monkeypatch, fake_credentials):
        f = tmp_path / "test.csv"
        f.write_text("a,b\n1,2\n")
        mock_client = type("Mock", (), {
            "create_lookup_file": lambda self, **kw: {
                "status_code": 409,
                "body": {"errors": [{"message": "File already exists"}]},
            }
        })()
        monkeypatch.setattr(create_lookup, "get_client", lambda: mock_client)
        success, msg = create_lookup.create_lookup(str(f))
        assert not success
        assert "already exists" in msg.lower()
