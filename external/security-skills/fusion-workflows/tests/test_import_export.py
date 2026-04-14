"""Tests for import_workflow.py — name extraction and duplicate checking."""

import import_workflow


class TestExtractNameFromYaml:
    """Test YAML name extraction (import_workflow has its own copy)."""

    def test_extracts_name(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\nname: Import Test\ntrigger:\n  type: On demand\n")
        assert import_workflow.extract_name_from_yaml(str(f)) == "Import Test"

    def test_returns_none_without_name(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\ntrigger:\n  type: On demand\n")
        assert import_workflow.extract_name_from_yaml(str(f)) is None


class TestCheckDuplicate:
    """Test duplicate name checking."""

    def test_finds_duplicate(self):
        existing = {"my workflow": {"id": "abc123", "name": "My Workflow"}}
        assert import_workflow.check_duplicate("My Workflow", existing) == "abc123"

    def test_case_insensitive(self):
        existing = {"my workflow": {"id": "abc123", "name": "My Workflow"}}
        assert import_workflow.check_duplicate("MY WORKFLOW", existing) == "abc123"

    def test_no_duplicate(self):
        existing = {"other workflow": {"id": "xyz", "name": "Other Workflow"}}
        assert import_workflow.check_duplicate("New Workflow", existing) is None
