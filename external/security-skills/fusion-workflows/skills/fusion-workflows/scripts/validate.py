"""
Validate CrowdStrike Fusion workflow YAML files.

Performs two levels of validation:
  1. Pre-flight: checks header comment, required top-level keys, PLACEHOLDER markers
  2. API: dry-run import via POST /workflows/entities/definitions/import/v1?validate_only=true

Usage:
    python validate.py workflow.yaml                    # Validate one file
    python validate.py *.yaml                           # Validate multiple files
    python validate.py --preflight-only workflow.yaml   # Skip API call
"""

import argparse
import re
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cs_auth import get_client

# Fix Windows console encoding
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REQUIRED_KEYS = {"name", "trigger"}
PLACEHOLDER_PATTERN = re.compile(r"PLACEHOLDER_[A-Z_]+")


def preflight_check(file_path):
    """
    Local checks before hitting the API. Returns list of warning/error strings.
    Empty list means all pre-flight checks passed.
    """
    issues = []

    if not os.path.isfile(file_path):
        return [f"File not found: {file_path}"]

    with open(file_path, encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()

    # Check header comment
    if not lines or not lines[0].startswith("#"):
        issues.append("WARNING: Missing header comment (first line should start with #)")

    # Check for required top-level keys (simple text scan — not a full YAML parser)
    for key in REQUIRED_KEYS:
        # Match key at start of line (top-level) followed by colon
        if not re.search(rf"^{key}\s*:", content, re.MULTILINE):
            issues.append(f"ERROR: Missing required top-level key '{key}'")

    # Check for PLACEHOLDER markers
    placeholders = PLACEHOLDER_PATTERN.findall(content)
    if placeholders:
        unique = sorted(set(placeholders))
        issues.append(f"ERROR: Found PLACEHOLDER markers that must be replaced: {', '.join(unique)}")

    return issues


def api_validate(file_path):
    """
    Validate via the CrowdStrike import API with validate_only=true.
    Returns (success: bool, message: str).
    """
    try:
        client = get_client()
        resp = client.import_definition(data_file=file_path, validate_only=True)
        body = resp["body"]
        errors = body.get("errors", [])
        if errors:
            msg = "; ".join(e.get("message", str(e)) for e in errors)
            return False, msg
        if resp["status_code"] not in (200, 201):
            return False, f"API returned status {resp['status_code']}"
        return True, "OK"
    except (ConnectionError, RuntimeError, OSError) as exc:
        return False, str(exc)


def validate_file(file_path, preflight_only=False):
    """
    Validate a single file. Returns (passed: bool, messages: list[str]).
    """
    messages = []

    # Pre-flight
    issues = preflight_check(file_path)
    has_errors = any(i.startswith("ERROR") for i in issues)
    messages.extend(issues)

    if has_errors:
        messages.append("Pre-flight FAILED — fix errors above before API validation")
        return False, messages

    if preflight_only:
        if not issues:
            messages.append("Pre-flight passed")
        return not has_errors, messages

    # API validation
    ok, msg = api_validate(file_path)
    if ok:
        messages.append("API validation passed")
    else:
        messages.append(f"API validation FAILED: {msg}")

    return ok, messages


def main():
    """CLI entry point for workflow validation."""
    parser = argparse.ArgumentParser(description="Validate Fusion workflow YAML files")
    parser.add_argument("files", nargs="+", metavar="FILE", help="YAML file(s) to validate")
    parser.add_argument("--preflight-only", action="store_true", help="Skip API validation")
    args = parser.parse_args()

    all_passed = True
    for fp in args.files:
        print(f"\n  {os.path.basename(fp)}")
        passed, messages = validate_file(fp, preflight_only=args.preflight_only)
        for m in messages:
            prefix = "    \u2713" if not m.startswith(("ERROR", "WARNING")) and "FAILED" not in m else "    \u2717"
            print(f"{prefix} {m}")
        if not passed:
            all_passed = False
        print()

    if all_passed:
        print("All files passed validation.")
    else:
        print("Some files failed validation.")
        sys.exit(1)


if __name__ == "__main__":
    main()
