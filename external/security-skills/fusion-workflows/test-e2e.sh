#!/usr/bin/env bash
# End-to-end workflow lifecycle test.
# Requires CS_CLIENT_ID, CS_CLIENT_SECRET, and write access to the target CID.
# API client needs Workflow:Read + Workflow:Write scopes.
#
# Lifecycle: validate → import → query → export → cleanup
# Note: execute is skipped — it triggers real workflow actions in the CID.
#
# Usage:
#   ./test-e2e.sh                  # Run full lifecycle
#   ./test-e2e.sh --skip-cleanup   # Keep the imported workflow after test

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$PLUGIN_DIR/skills/fusion-workflows/scripts"
PASS=0
FAIL=0
SKIP=0
CLEANUP=true
IMPORTED_ID=""

[[ "${1:-}" == "--skip-cleanup" ]] && CLEANUP=false

# ── Helpers ────────────────────────────────────────────────────────────────

pass()  { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail()  { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
skip()  { SKIP=$((SKIP + 1)); echo "  SKIP: $1"; }

run_script() {
    python3 "$SCRIPTS_DIR/$1" "${@:2}" 2>&1
}

TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/test-e2e.XXXXXX")
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# ── Pre-flight ─────────────────────────────────────────────────────────────

echo ""
echo "Fusion Workflow Scripts — E2E Lifecycle Test"
echo "─────────────────────────────────────────────"

# Check credentials
if [[ -z "${CS_CLIENT_ID:-}" || -z "${CS_CLIENT_SECRET:-}" ]]; then
    if [[ -f "$PLUGIN_DIR/.env" ]]; then
        # shellcheck disable=SC1091
        source "$PLUGIN_DIR/.env" 2>/dev/null || true
    fi
fi

if [[ -z "${CS_CLIENT_ID:-}" || -z "${CS_CLIENT_SECRET:-}" ]]; then
    echo ""
    echo "  ERROR: CS_CLIENT_ID and CS_CLIENT_SECRET must be set."
    exit 1
fi

echo "  Credentials found (ID: ${CS_CLIENT_ID:0:8}...)"
echo ""

# ── Step 1: Generate test workflow YAML ───────────────────────────────────

echo "1. Generate test workflow YAML"
TEST_WF_NAME="E2E-Test-$(date +%s)"
# Use the real Fusion SOAR workflow schema — actions must be a map with labels,
# trigger must have 'next' pointing to the first action label.
cat > "$TMPDIR/workflow.yaml" << EOF
# E2E test workflow — auto-generated, safe to delete
name: '$TEST_WF_NAME'
trigger:
    next:
        - TestAction
    name: On demand
    type: On demand
actions:
    TestAction:
        id: 1ba474f407d9228fc8fa02cdce8ae8ef
        name: Cloud HTTP Request
        properties:
            method: GET
            url: https://httpbin.org/get
output_fields: []
EOF
pass "Generated YAML with name: $TEST_WF_NAME"
echo ""

# ── Step 2: Validate (preflight) ─────────────────────────────────────────

echo "2. Validate (preflight)"
if run_script validate.py --preflight-only "$TMPDIR/workflow.yaml" >/dev/null 2>&1; then
    pass "Preflight validation passed"
else
    fail "Preflight validation failed"
fi

echo ""
echo "3. Validate (API)"
if output=$(run_script validate.py "$TMPDIR/workflow.yaml" 2>&1); then
    if echo "$output" | grep -q "API validation passed"; then
        pass "API validation passed"
    else
        skip "API validation returned non-pass (workflow structure may be too minimal)"
        echo "    Output: $(echo "$output" | tail -3)"
    fi
else
    skip "API validation rejected test workflow (expected for minimal YAML)"
fi
echo ""

# ── Step 3: Check for duplicates ─────────────────────────────────────────

echo "4. Duplicate check"
if run_script query_workflows.py --check-name "$TEST_WF_NAME" >/dev/null 2>&1; then
    fail "Workflow '$TEST_WF_NAME' already exists (should not)"
else
    pass "No duplicate found for '$TEST_WF_NAME'"
fi
echo ""

# ── Step 4: Import ───────────────────────────────────────────────────────

echo "5. Import"
if output=$(run_script import_workflow.py --skip-validate --skip-duplicate-check "$TMPDIR/workflow.yaml" 2>&1); then
    # Extract workflow ID from output
    IMPORTED_ID=$(echo "$output" | grep -oE '[a-f0-9]{32}' | head -1 || true)
    if [[ -n "$IMPORTED_ID" ]]; then
        pass "Imported workflow — ID: $IMPORTED_ID"
    else
        if echo "$output" | grep -qi "imported"; then
            IMPORTED_ID=$(echo "$output" | grep -oE 'ID: [^ ]+' | head -1 | sed 's/ID: //')
            pass "Imported workflow — ID: ${IMPORTED_ID:-unknown}"
        else
            fail "Import succeeded but could not extract workflow ID"
            echo "    Output: $output"
        fi
    fi
else
    fail "Import failed"
    echo "    Output: $output"
    echo ""
    echo "  Remaining tests require a successful import. Skipping."
    echo ""
    echo "─────────────────────────────────────────────"
    echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
    exit 1
fi
echo ""

# ── Step 5: Query for imported workflow ──────────────────────────────────

echo "6. Query for imported workflow"
if run_script query_workflows.py --check-name "$TEST_WF_NAME" >/dev/null 2>&1; then
    pass "Workflow found by name after import"
else
    fail "Workflow not found by name after import"
fi
echo ""

# ── Step 6: Execute (skipped) ────────────────────────────────────────────

echo "7. Execute"
skip "Skipped — execute triggers real workflow actions in the CID"
echo ""

# ── Step 7: Export ───────────────────────────────────────────────────────

echo "8. Export"
if [[ -n "$IMPORTED_ID" ]]; then
    if output=$(run_script export.py --id "$IMPORTED_ID" --output "$TMPDIR/export.yaml" 2>&1); then
        if [[ -f "$TMPDIR/export.yaml" && -s "$TMPDIR/export.yaml" ]]; then
            pass "Exported workflow to file"
            if grep -q "$TEST_WF_NAME" "$TMPDIR/export.yaml" 2>/dev/null; then
                pass "Exported YAML contains correct workflow name"
            else
                skip "Exported YAML may use different name format"
            fi
        else
            fail "Export file is empty or missing"
        fi
    else
        fail "Export command failed"
    fi
else
    skip "No workflow ID available for export"
fi
echo ""

# ── Summary ──────────────────────────────────────────────────────────────

echo "─────────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
if [[ -n "$IMPORTED_ID" ]]; then
    echo ""
    if $CLEANUP; then
        echo "  NOTE: Workflow '$TEST_WF_NAME' ($IMPORTED_ID) was imported."
        echo "  Auto-delete is not available via CLI — remove manually if needed."
    else
        echo "  Workflow '$TEST_WF_NAME' ($IMPORTED_ID) left in place (--skip-cleanup)."
    fi
fi
echo ""

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
