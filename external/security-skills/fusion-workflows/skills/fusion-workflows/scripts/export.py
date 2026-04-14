"""
Export CrowdStrike Fusion workflow definitions as YAML or list all definitions.

Usage:
    python export.py --id <wf_id>                      # Print YAML to stdout
    python export.py --id <wf_id> --output file.yaml   # Save to file
    python export.py --list                             # List all definitions
    python export.py --list --json                      # Machine-readable
"""

import argparse
import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cs_auth import get_client

# Fix Windows console encoding
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def export_workflow(workflow_id):
    """
    Export a workflow as YAML. Returns the raw YAML string.
    """
    client = get_client()
    resp = client.export_definition(id=workflow_id)

    # FalconPy returns raw bytes/str for YAML content-type responses
    if isinstance(resp, bytes):
        return resp.decode("utf-8")
    if isinstance(resp, str):
        return resp

    # Dict response means JSON (typically an error)
    body = resp.get("body", resp) if isinstance(resp, dict) else resp
    if isinstance(body, dict):
        errors = body.get("errors", [])
        if errors:
            msg = "; ".join(e.get("message", str(e)) for e in errors)
            print(f"  Export error: {msg}", file=sys.stderr)
            sys.exit(1)

    return str(resp)


def list_definitions(limit=100, offset=0):
    """List all workflow definitions."""
    client = get_client()
    all_defs = []
    while True:
        resp = client.search_definitions(limit=limit, offset=offset)
        body = resp["body"]
        resources = body.get("resources", [])
        if not resources:
            break
        all_defs.extend(resources)
        meta = body.get("meta", {}).get("pagination", {})
        total = meta.get("total", 0)
        offset += len(resources)
        if offset >= total:
            break
    return all_defs


def format_definition(d):
    """Format a definition for human display."""
    did = d.get("id", "?")
    name = d.get("name", "?")
    enabled = d.get("enabled", False)
    trigger_type = d.get("trigger", {}).get("type", "?")
    status = "enabled" if enabled else "disabled"
    return f"  {name}\n    ID      : {did}\n    Trigger : {trigger_type}\n    Status  : {status}"


def main():
    """CLI entry point for workflow export."""
    parser = argparse.ArgumentParser(description="Export Fusion workflow definitions")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--id", metavar="WF_ID", help="Workflow definition ID to export")
    group.add_argument("--list", "-l", action="store_true", help="List all definitions")
    parser.add_argument("--output", "-o", metavar="FILE", help="Save exported YAML to file")
    parser.add_argument("--json", action="store_true", help="Machine-readable JSON output")
    args = parser.parse_args()

    if args.id:
        yaml_content = export_workflow(args.id)
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(yaml_content)
            print(f"  Exported to {args.output}")
        else:
            print(yaml_content)

    elif args.list:
        defs = list_definitions()
        if args.json:
            out = []
            for d in defs:
                out.append({
                    "id": d.get("id", ""),
                    "name": d.get("name", ""),
                    "enabled": d.get("enabled", False),
                    "trigger_type": d.get("trigger", {}).get("type", ""),
                })
            print(json.dumps(out, indent=2))
        else:
            print(f"\nWorkflow definitions ({len(defs)}):\n")
            for d in defs:
                print(format_definition(d))
                print()


if __name__ == "__main__":
    main()
