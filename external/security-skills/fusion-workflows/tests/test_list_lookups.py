"""Tests for list_lookups.py."""

from unittest.mock import MagicMock

import list_lookups


class TestFormatLookup:
    """Test human-readable formatting."""

    def test_string_item(self):
        result = list_lookups.format_lookup("blocklist.csv")
        assert "blocklist.csv" in result

    def test_dict_item_with_metadata(self):
        item = {
            "name": "blocklist.csv",
            "search_domain": "falcon",
            "size": "1024",
            "last_modified_timestamp": "2026-04-01T10:00:00Z",
        }
        result = list_lookups.format_lookup(item)
        assert "blocklist.csv" in result
        assert "falcon" in result
        assert "1024" in result
        assert "2026-04-01" in result

    def test_empty_dict_shows_question_mark(self):
        result = list_lookups.format_lookup({})
        assert "?" in result


class TestFormatJson:
    """Test JSON formatting."""

    def test_formats_string_items(self):
        items = ["a.csv", "b.csv"]
        result = list_lookups.format_json(items)
        assert '"name": "a.csv"' in result
        assert '"name": "b.csv"' in result

    def test_formats_dict_items(self):
        items = [
            {"name": "a.csv", "search_domain": "falcon", "size": "100"},
            {"name": "b.csv", "search_domain": "third-party", "size": "200"},
        ]
        result = list_lookups.format_json(items)
        assert '"name": "a.csv"' in result
        assert '"name": "b.csv"' in result


class TestFetchAllLookups:
    """Test pagination logic."""

    def test_single_page(self, monkeypatch, fake_credentials):
        mock_client = MagicMock()
        mock_client.list_lookup_files.return_value = {
            "body": {
                "resources": ["a.csv", "b.csv"],
                "meta": {"pagination": {"total": 2}},
            }
        }
        monkeypatch.setattr(list_lookups, "get_client", lambda: mock_client)
        result = list_lookups.fetch_all_lookups()
        assert len(result) == 2

    def test_multiple_pages(self, monkeypatch, fake_credentials):
        mock_client = MagicMock()
        mock_client.list_lookup_files.side_effect = [
            {
                "body": {
                    "resources": ["a.csv"],
                    "meta": {"pagination": {"total": 2}},
                }
            },
            {
                "body": {
                    "resources": ["b.csv"],
                    "meta": {"pagination": {"total": 2}},
                }
            },
        ]
        monkeypatch.setattr(list_lookups, "get_client", lambda: mock_client)
        result = list_lookups.fetch_all_lookups()
        assert len(result) == 2

    def test_empty_results(self, monkeypatch, fake_credentials):
        mock_client = MagicMock()
        mock_client.list_lookup_files.return_value = {
            "body": {"resources": [], "meta": {"pagination": {"total": 0}}}
        }
        monkeypatch.setattr(list_lookups, "get_client", lambda: mock_client)
        result = list_lookups.fetch_all_lookups()
        assert result == []


class TestSearchLookups:
    """Test FQL filter construction."""

    def test_search_passes_fql_filter(self, monkeypatch, fake_credentials):
        mock_client = MagicMock()
        mock_client.list_lookup_files.return_value = {
            "body": {
                "resources": ["blocklist.csv"],
                "meta": {"pagination": {"total": 1}},
            }
        }
        monkeypatch.setattr(list_lookups, "get_client", lambda: mock_client)
        result = list_lookups.search_lookups("blocklist")
        assert len(result) == 1
        call_kwargs = mock_client.list_lookup_files.call_args[1]
        assert call_kwargs["filter"] == "name:~'blocklist'"
