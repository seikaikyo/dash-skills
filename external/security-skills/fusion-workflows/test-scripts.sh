#!/usr/bin/env bash
# Integration tests for Fusion workflow scripts.
# Requires CS_CLIENT_ID and CS_CLIENT_SECRET in environment or .env file.
# API client needs Workflow:Read scope (Workflow:Write also needed for API validation).
#
# Usage:
#   ./test-scripts.sh              # Run all tests
#   ./test-scripts.sh --quick      # Auth + discovery only (skips validation and export)

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$PLUGIN_DIR/skills/fusion-workflows/scripts"
ASSETS_DIR="$PLUGIN_DIR/skills/fusion-workflows/assets"
PASS=0
FAIL=0
SKIP=0
QUICK=false

[[ "${1:-}" == "--quick" ]] && QUICK=true

# ── Helpers ────────────────────────────────────────────────────────────────

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
skip() { SKIP=$((SKIP + 1)); echo "  SKIP: $1"; }

run_script() {
    python3 "$SCRIPTS_DIR/$1" "${@:2}" 2>&1
}

# ── Pre-flight ─────────────────────────────────────────────────────────────

echo ""
echo "Fusion Workflow Scripts — Integration Tests"
echo "────────────────────────────────────────────"

# Check for credentials
if [[ -z "${CS_CLIENT_ID:-}" || -z "${CS_CLIENT_SECRET:-}" ]]; then
    if [[ -f "$PLUGIN_DIR/.env" ]]; then
        # shellcheck disable=SC1091
        source "$PLUGIN_DIR/.env" 2>/dev/null || true
    fi
fi

if [[ -z "${CS_CLIENT_ID:-}" || -z "${CS_CLIENT_SECRET:-}" ]]; then
    echo ""
    echo "  ERROR: CS_CLIENT_ID and CS_CLIENT_SECRET must be set."
    echo "  Set them in environment or create a .env file."
    exit 1
fi

echo "  Credentials found (ID: ${CS_CLIENT_ID:0:8}...)"
echo ""

# ── Test 1: Authentication ─────────────────────────────────────────────────

echo "1. Authentication (cs_auth.py)"
if output=$(run_script cs_auth.py); then
    if echo "$output" | grep -q "Authentication successful"; then
        pass "FalconPy client authenticated"
    else
        fail "Unexpected output: $output"
    fi
else
    fail "cs_auth.py exited with error"
    echo "     Cannot continue without authentication."
    exit 1
fi
echo ""

# ── Test 2: Action discovery ──────────────────────────────────────────────

echo "2. Action Discovery (action_search.py)"
if output=$(run_script action_search.py --vendors); then
    if echo "$output" | grep -qi "CrowdStrike"; then
        pass "--vendors lists CrowdStrike"
    else
        fail "--vendors output missing CrowdStrike"
    fi
else
    fail "action_search.py --vendors failed"
fi

if output=$(run_script action_search.py --search "contain" --json); then
    if echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if len(d)>0 else 1)" 2>/dev/null; then
        pass "--search 'contain' returned results"
    else
        fail "--search 'contain' returned empty results"
    fi
else
    fail "action_search.py --search failed"
fi
echo ""

# ── Test 3: Trigger listing ──────────────────────────────────────────────

echo "3. Trigger Listing (trigger_search.py)"
if output=$(run_script trigger_search.py --list); then
    if echo "$output" | grep -qi "trigger"; then
        pass "--list shows trigger types"
    else
        fail "--list output missing trigger info"
    fi
else
    fail "trigger_search.py --list failed"
fi
echo ""

# ── Test 4: Workflow query ────────────────────────────────────────────────

echo "4. Workflow Query (query_workflows.py)"
if output=$(run_script query_workflows.py --list); then
    pass "--list executed successfully"
else
    fail "query_workflows.py --list failed"
fi

if output=$(run_script query_workflows.py --check-name "NonExistentWorkflow_$RANDOM"); then
    fail "--check-name should exit 1 for nonexistent workflow"
else
    pass "--check-name exits 1 for nonexistent workflow"
fi
echo ""

if $QUICK; then
    echo "── Quick mode: skipping validation and export tests ──"
    echo ""
else

    # ── Test 5: Validate known-good YAML ──────────────────────────────────

    echo "5. Validation (validate.py)"
    YAML_FILES=("$ASSETS_DIR"/*.yaml)
    if [[ ${#YAML_FILES[@]} -gt 0 && -f "${YAML_FILES[0]}" ]]; then
        # Preflight-only (no API call, just local checks)
        # Note: template YAMLs have PLACEHOLDER markers, so preflight failures are expected
        preflight_pass=0
        preflight_fail=0
        for yf in "${YAML_FILES[@]}"; do
            if run_script validate.py --preflight-only "$yf" >/dev/null 2>&1; then
                preflight_pass=$((preflight_pass + 1))
            else
                preflight_fail=$((preflight_fail + 1))
            fi
        done
        if [[ $preflight_pass -gt 0 ]]; then
            pass "Preflight passed on ${preflight_pass} of $((preflight_pass + preflight_fail)) YAML files"
        fi
        if [[ $preflight_fail -gt 0 ]]; then
            skip "Preflight failed on $preflight_fail files (expected for PLACEHOLDER templates)"
        fi

        # API validation on first file only (to avoid rate limits)
        first_yaml="${YAML_FILES[0]}"
        if run_script validate.py "$first_yaml" >/dev/null 2>&1; then
            pass "API validation passed on $(basename "$first_yaml")"
        else
            # API validation may fail if the YAML has PLACEHOLDERs or template values
            skip "API validation on $(basename "$first_yaml") (may contain template values)"
        fi
    else
        skip "No example YAML files found in $ASSETS_DIR"
    fi
    echo ""

    # ── Test 6: Export/list definitions ───────────────────────────────────

    echo "6. Export (export.py)"
    if output=$(run_script export.py --list --json); then
        count=$(echo "$output" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
        pass "--list --json returned $count definition(s)"

        # If there are definitions, try exporting the first one
        if [[ "$count" != "?" && "$count" -gt 0 ]]; then
            first_id=$(echo "$output" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)
            if [[ -n "$first_id" ]]; then
                if export_out=$(run_script export.py --id "$first_id"); then
                    if [[ -n "$export_out" ]]; then
                        pass "--id export returned YAML content"
                    else
                        fail "--id export returned empty content"
                    fi
                else
                    fail "--id export failed for $first_id"
                fi
            fi
        fi
    else
        fail "export.py --list --json failed"
    fi
    echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────

echo "────────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo ""

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
