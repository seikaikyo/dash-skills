"""Tests for get_lookup.py."""

import get_lookup


class TestGetLookup:
    """Test response handling for different return types."""

    def test_handles_bytes_response(self, monkeypatch, fake_credentials):
        mock_client = type("Mock", (), {
            "get_lookup_file": lambda self, **kw: b"ip,category\n10.0.0.1,c2\n"
        })()
        monkeypatch.setattr(get_lookup, "get_client", lambda: mock_client)
        result = get_lookup.get_lookup("test.csv")
        assert "ip,category" in result
        assert "10.0.0.1" in result

    def test_handles_string_response(self, monkeypatch, fake_credentials):
        mock_client = type("Mock", (), {
            "get_lookup_file": lambda self, **kw: "ip,category\n10.0.0.1,c2\n"
        })()
        monkeypatch.setattr(get_lookup, "get_client", lambda: mock_client)
        result = get_lookup.get_lookup("test.csv")
        assert "ip,category" in result

    def test_handles_error_response(self, monkeypatch, fake_credentials):
        mock_client = type("Mock", (), {
            "get_lookup_file": lambda self, **kw: {
                "body": {"errors": [{"message": "File not found"}]}
            }
        })()
        monkeypatch.setattr(get_lookup, "get_client", lambda: mock_client)
        try:
            get_lookup.get_lookup("missing.csv")
            assert False, "Should have called sys.exit"
        except SystemExit as e:
            assert e.code == 1
