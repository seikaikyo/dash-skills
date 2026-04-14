"""Tests for trigger_search.py — built-in catalog and formatting."""

import trigger_search


class TestTriggerCatalog:
    """Test the built-in trigger type catalog."""

    def test_catalog_has_required_types(self):
        assert "On demand" in trigger_search.TRIGGER_CATALOG
        assert "Event" in trigger_search.TRIGGER_CATALOG
        assert "Scheduled" in trigger_search.TRIGGER_CATALOG
        assert "API" in trigger_search.TRIGGER_CATALOG

    def test_each_type_has_description(self):
        for name, info in trigger_search.TRIGGER_CATALOG.items():
            assert "description" in info, f"{name} missing description"
            assert len(info["description"]) > 0

    def test_each_type_has_yaml_example(self):
        for name, info in trigger_search.TRIGGER_CATALOG.items():
            assert "yaml_example" in info, f"{name} missing yaml_example"
            assert "trigger:" in info["yaml_example"]
