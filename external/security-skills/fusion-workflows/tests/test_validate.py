"""Tests for validate.py — preflight checks (no API calls needed)."""

import validate


class TestPreflightCheck:
    """Test local YAML validation checks."""

    def test_valid_yaml(self, tmp_path):
        f = tmp_path / "good.yaml"
        f.write_text("# Header comment\nname: Test Workflow\ntrigger:\n  type: On demand\n")
        issues = validate.preflight_check(str(f))
        assert issues == []

    def test_missing_header_comment(self, tmp_path):
        f = tmp_path / "no_header.yaml"
        f.write_text("name: Test\ntrigger:\n  type: On demand\n")
        issues = validate.preflight_check(str(f))
        assert any("header comment" in i for i in issues)

    def test_missing_name_key(self, tmp_path):
        f = tmp_path / "no_name.yaml"
        f.write_text("# Header\ntrigger:\n  type: On demand\n")
        issues = validate.preflight_check(str(f))
        assert any("'name'" in i for i in issues)

    def test_missing_trigger_key(self, tmp_path):
        f = tmp_path / "no_trigger.yaml"
        f.write_text("# Header\nname: Test\n")
        issues = validate.preflight_check(str(f))
        assert any("'trigger'" in i for i in issues)

    def test_placeholder_markers_detected(self, tmp_path):
        f = tmp_path / "placeholders.yaml"
        f.write_text("# Header\nname: Test\ntrigger:\n  type: On demand\nactions:\n  MyAction:\n    id: PLACEHOLDER_ACTION_ID\n")
        issues = validate.preflight_check(str(f))
        assert any("PLACEHOLDER" in i for i in issues)

    def test_file_not_found(self):
        issues = validate.preflight_check("/nonexistent/file.yaml")
        assert any("not found" in i.lower() for i in issues)

    def test_multiple_placeholders_listed(self, tmp_path):
        f = tmp_path / "multi.yaml"
        f.write_text("# Header\nname: Test\ntrigger:\n  type: On demand\nactions:\n  A:\n    id: PLACEHOLDER_ACTION_ID\n  B:\n    id: PLACEHOLDER_TRIGGER_ID\n")
        issues = validate.preflight_check(str(f))
        placeholder_issues = [i for i in issues if "PLACEHOLDER" in i]
        assert len(placeholder_issues) == 1  # Single message listing all
        assert "PLACEHOLDER_ACTION_ID" in placeholder_issues[0]
        assert "PLACEHOLDER_TRIGGER_ID" in placeholder_issues[0]


class TestValidateFile:
    """Test the combined validation flow."""

    def test_preflight_only_passes(self, tmp_path):
        f = tmp_path / "good.yaml"
        f.write_text("# Header\nname: Test\ntrigger:\n  type: On demand\n")
        passed, messages = validate.validate_file(str(f), preflight_only=True)
        assert passed is True
        assert any("passed" in m.lower() for m in messages)

    def test_preflight_only_fails_on_errors(self, tmp_path):
        f = tmp_path / "bad.yaml"
        f.write_text("# Header\ntrigger:\n  type: On demand\n")
        passed, messages = validate.validate_file(str(f), preflight_only=True)
        assert passed is False

    def test_preflight_errors_block_api_call(self, tmp_path):
        f = tmp_path / "bad.yaml"
        f.write_text("# Header\nname: PLACEHOLDER_NAME\ntrigger:\n  type: On demand\n")
        passed, messages = validate.validate_file(str(f), preflight_only=False)
        assert passed is False
        assert any("fix errors" in m.lower() for m in messages)
