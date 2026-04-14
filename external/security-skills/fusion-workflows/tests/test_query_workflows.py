"""Tests for query_workflows.py — YAML name extraction and formatting."""

import query_workflows


class TestExtractNameFromYaml:
    """Test workflow name extraction from YAML files."""

    def test_simple_name(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\nname: My Workflow\ntrigger:\n  type: On demand\n")
        assert query_workflows.extract_name_from_yaml(str(f)) == "My Workflow"

    def test_quoted_name(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\nname: 'Quoted Name'\ntrigger:\n  type: On demand\n")
        assert query_workflows.extract_name_from_yaml(str(f)) == "Quoted Name"

    def test_double_quoted_name(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text('# Header\nname: "Double Quoted"\ntrigger:\n  type: On demand\n')
        assert query_workflows.extract_name_from_yaml(str(f)) == "Double Quoted"

    def test_no_name_key(self, tmp_path):
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\ntrigger:\n  type: On demand\n")
        assert query_workflows.extract_name_from_yaml(str(f)) is None

    def test_indented_name_ignored(self, tmp_path):
        """Only top-level name: should match, not nested ones."""
        f = tmp_path / "wf.yaml"
        f.write_text("# Header\ntrigger:\n  name: Nested Name\n")
        assert query_workflows.extract_name_from_yaml(str(f)) is None

    def test_file_not_found(self):
        assert query_workflows.extract_name_from_yaml("/nonexistent") is None


class TestFormatDefinition:
    """Test definition formatting."""

    def test_formats_basic_definition(self):
        d = {
            "id": "abc123",
            "name": "Test Workflow",
            "enabled": True,
            "trigger": {"type": "On demand"},
            "last_modified_timestamp": "2026-01-01",
        }
        output = query_workflows.format_definition(d)
        assert "Test Workflow" in output
        assert "abc123" in output
        assert "enabled" in output
        assert "On demand" in output

    def test_formats_disabled_workflow(self):
        d = {"id": "x", "name": "Disabled", "enabled": False, "trigger": {"type": "API"}}
        output = query_workflows.format_definition(d)
        assert "disabled" in output
