# Falcon Next-Gen SIEM Lookup Files

A Claude Code skill for managing CrowdStrike Falcon Next-Gen SIEM lookup files — CSV or JSON reference tables used with the `match()` function in CQL queries.

## Quick Start

```bash
# Test credentials
python scripts/cs_auth.py

# List existing lookup files
python scripts/list_lookups.py --list

# Upload a new lookup file
python scripts/create_lookup.py --file data.csv --name "my-lookup.csv"

# Download a lookup file
python scripts/get_lookup.py --name "my-lookup.csv"

# Update a lookup file
python scripts/update_lookup.py --name "my-lookup.csv" --file updated-data.csv

# Delete a lookup file
python scripts/delete_lookup.py --name "my-lookup.csv" --confirm
```

## Prerequisites

- Python 3.10+ with `crowdstrike-falconpy` installed
- CrowdStrike API credentials with NGSIEM:Read and NGSIEM:Write scopes

See [SKILL.md](SKILL.md) for full documentation including CQL `match()` function reference.
