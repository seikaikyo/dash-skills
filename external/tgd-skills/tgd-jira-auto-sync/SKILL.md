---
name: tgd-jira-auto-sync
description: "Parse TASKS.md and auto-create Jira Data Center issues in a single Sprint. Use as conditional skill in /tgd-plan phase after TASKS.md is generated."
trigger: "After /tgd-plan generates TASKS.md, when user wants Jira tickets created"
---

# Jira Auto-Sync (TASKS.md → Jira Sprint)

## Overview

Parses the `TASKS.md` produced by `/tgd-plan` and creates Jira issues in the company's **Jira Data Center** instance, all assigned to a single Sprint. Uses `curl` + Jira REST API v2 — no external CLI binary needed, works behind company proxies.

## Prerequisites

The user MUST provide these before the skill runs:

```
JIRA_URL      = https://jira.company.com          (Data Center base URL)
JIRA_TOKEN = Personal Token (PAT)
JIRA_PROJECT   = Project key (e.g. ENG, FE, BE) — 必填
```

**Setup (one-time):**
```bash
# Test connection (Bearer auth)
curl -x "" -s -H "Authorization: Bearer $JIRA_TOKEN" "$JIRA_URL/rest/api/2/myself" | python3 -m json.tool
```
If it returns user info, auth works. If 401/403, check credentials or proxy settings.

**Priority Mapping:**
Map TASKS.md priority to Jira priority names (check your instance via `curl -x "" $JIRA_URL/rest/api/2/priority`):
- High → "High" (or "Highest", "Critical")
- Medium → "Medium" (or "Normal")
- Low → "Low" (or "Lowest")

## Proxy / Firewall Handling

Company networks often intercept HTTPS. If curl fails with SSL errors or timeouts:

```bash
# Option 1: Set proxy (if Jira is external or proxy is required to reach it)
export HTTPS_PROXY=http://proxy.company.com:8080

# Option 2: Bypass proxy for internal Jira Data Center (if proxy is globally set but Jira is on intranet)
# Use curl -x "" to bypass the proxy
curl -x "" -s -H "Authorization: Bearer $JIRA_TOKEN" ...

# Option 3: MITM proxy re-signs TLS — point curl at the company CA bundle
curl --cacert /path/to/company-ca-bundle.crt ...
# or: export CURL_CA_BUNDLE=/path/to/company-ca-bundle.crt
```

**Never disable certificate verification** (`curl -k`, `NODE_TLS_REJECT_UNAUTHORIZED=0`).
The request carries your Jira PAT — sending it over an unverified connection hands
the token to whoever can intercept. Ask IT for the CA bundle path instead.

## TASKS.md Format

The skill parses the **canonical TASKS.md format** defined in
`tgd-planning-and-task-breakdown` (the only TASKS.md format). Per task section:

```markdown
## Task 1: [User Story Title] (Story ID: US-01)

### 1. Context & Goal
[Goal + **Priority**: High/Medium/Low + **Dependencies**]

### 2. Technical Design
[Schema / API contract]

### 3. Acceptance Criteria (BDD)
- **AC-1.1** — **Given** [context] **When** [action] **Then** [result]
  - **Regression**: Yes [R] / No
  - **Test**: `tests/path` (present once /tgd-develop has run)

### 4. Files Likely Touched
- `src/foo.py`
```

Extract per task: number, title (summary), Context & Goal (description),
Priority, the `AC-<task>.<n>` criteria, and Files Likely Touched. Keep the
original AC ids — they are the traceability link back to TASKS.md.

## Execution Steps

### Step 1: Parse TASKS.md

Read `$TGD_DIR/<feature-name>/TASKS.md` and extract each task block:
- Task number/ID
- Title (summary)
- Description
- Acceptance Criteria (as checklist)
- Files Likely Touched
- Estimate (if present)

### Step 2: Discover Issue Types and Required Fields (Jira 9.0+ DC Compliant)

**Step 2a: Fetch Available Issue Types for the Project**
Use the Jira REST API v2 (Jira 9.0+ DC compliant) to get all available issue types for the project.

```bash
curl -x "" -s \
  "$JIRA_URL/rest/api/2/issue/createmeta/$JIRA_PROJECT/issuetypes" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" > /tmp/jira_issuetypes.json
```

**Parse and present issue types:**
```bash
# JIRA_PROJECT must be exported to the environment for the heredoc to see it
python3 << 'PYEOF'
import json, os

data = json.load(open("/tmp/jira_issuetypes.json"))
issuetypes = data.get("values", [])

print(f"📌 Project: {os.environ['JIRA_PROJECT']}")
print("Available Issue Types:")
for i, it in enumerate(issuetypes, 1):
    print(f"  [{i}] {it['name']} (ID: {it['id']})")
PYEOF
```

> 🛑 **Action:** Present the issue type list to the user. Default to **Story** if present. Store their choice as `ISSUE_TYPE_ID`.

**Step 2b: Fetch Required Fields for the Selected Issue Type**
Query the exact metadata for the chosen `ISSUE_TYPE_ID`. This returns **only** the fields available for that specific issue type in this project, including required flags and allowed values.

```bash
curl -x "" -s \
  "$JIRA_URL/rest/api/2/issue/createmeta/$JIRA_PROJECT/issuetypes/$ISSUE_TYPE_ID" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" > /tmp/jira_meta.json
```

**Parse and present required custom fields:**
```bash
python3 << 'PYEOF'
import json, subprocess, os

meta = json.load(open("/tmp/jira_meta.json"))
fields = meta.get("fields", {})
project_key = os.environ['JIRA_PROJECT']

print(f"🔍 Required Custom Fields for {project_key} (IssueType ID: {os.environ['ISSUE_TYPE_ID']}):")

required_fields = []
for field_id, field_info in fields.items():
    if field_info.get("required") and field_id not in ("summary", "description", "project", "issuetype", "priority", "labels", "reporter"):
        required_fields.append({
            "id": field_id,
            "name": field_info["name"],
            "schema": field_info.get("schema", {}),
            "allowed_values": field_info.get("allowedValues", [])
        })

for rf in required_fields:
    schema = rf["schema"]
    allowed = rf["allowed_values"]
    field_id = rf["id"]
    
    # Case 1: Has static allowedValues (Dropdown, select, components)
    if allowed:
        options = [v.get("name", v.get("value", str(v))) for v in allowed]
        print(f"  • {field_id}: {rf['name']} (type: {schema.get('type')}) - Options: {options}")
    
    # Case 2: Dynamic Epic Link / Parent (Fetch existing epics in project)
    elif "epic" in rf["name"].lower() or "parent" in rf["name"].lower():
        print(f"  • {field_id}: {rf['name']} (type: {schema.get('type')}) - Dynamic Epic Link")
        print("    🔍 Querying active Epics in JIRA...")
        # Run JQL to get Epics
        try:
            res = subprocess.run([
                "curl", "-x", "", "-s", 
                "-H", f"Authorization: Bearer {os.environ.get('JIRA_TOKEN')}",
                f"{os.environ.get('JIRA_URL')}/rest/api/2/search?jql=project={project_key}+AND+issuetype=Epic&maxResults=50&fields=key,summary"
            ], capture_output=True, text=True)
            epics_data = json.loads(res.stdout)
            epics = epics_data.get("issues", [])
            if epics:
                print("    Available Epics:")
                for ep in epics:
                    print(f"      - [{ep['key']}] {ep.get('fields', {}).get('summary')}")
            else:
                print("    ⚠️ No Epics found in this project.")
        except Exception as e:
            print(f"    ⚠️ Failed to query Epics: {str(e)}")
    
    # Case 3: Standard open input (string, date, number)
    else:
        print(f"  • {field_id}: {rf['name']} (type: {schema.get('type')}) - [Open text/value input]")

if not required_fields:
    print("  ✅ No required custom fields.")

print("\n===META_JSON===")
print(json.dumps(meta))
PYEOF
```

> 🛑 **Agent Interaction Guide (Mandatory):**
> When you find required fields, you MUST ask the user one-by-one or in a clean list. Follow this conversational style:
>
> ```
> 🔍 I found the following required fields for project [ENG] with IssueType [Story]:
>
> 1. customfield_10100: "Component" (type: option)
>    Options: [1] Backend  [2] Frontend  [3] Database
>    👉 Please reply with the number or name to select.
>
> 2. customfield_10200: "Epic Link" (type: string)
>    Options (Active Epics found via JQL):
>    [1] [ENG-100] User Auth Redesign
>    [2] [ENG-101] Core Database Migration
>    👉 Please reply with the number or Epic Key.
>
> 3. customfield_10300: "Target Release Date" (type: date)
>    👉 Please reply with the value (Format: YYYY-MM-DD).
> ```
>
> **Do not guess or skip.** Store all user answers and dynamically build the payload under `fields`.

### Step 3: Create Issues

For each parsed task, construct a JSON payload and create a Jira issue.

**📝 Summary Format Rule (Mandatory):**
The summary MUST be structured in the classic User Story format and strictly under 255 characters.
Format: `[feature-name] As a <user role>, I want <action/goal> so that <benefit>`
> 💡 Example: `[jwt-auth] As a user, I want to login via email to access my secure dashboard`

**📝 Description Format Rule (Mandatory):**
The Agent MUST construct the `DESCRIPTION` variable using this Wiki Markup structure. Do NOT deviate from this format.
```
h3. Background
{noformat}
<Why is this needed? Current pain point or context from PRD/SPEC.>
{noformat}

h3. Goal
{noformat}
<What exactly are we building? The desired measurable outcome.>
{noformat}

h3. Acceptance Criteria
{noformat}
AC-<task>.<n> (copy the exact id from TASKS.md — it is the traceability link):
Given <initial context>
When <action occurs>
Then <expected result>
{noformat}

h3. Technical Notes
{noformat}
Files Likely Touched:
- <path/to/file1>
- <path/to/file2>
Estimate: <X points>
{noformat}
```

```bash
# 1. Export variables for the Python script (avoids bash escaping hell)
export SUMMARY="[<feature-name>] Task Title"
export PRIORITY="High"
export DESCRIPTION="h3. Background..."
export FEATURE_NAME="<feature-name>"

# 2. Construct the payload via Python
python3 << 'EOF' > /tmp/jira_payload.json
import json, os

payload = {
    "fields": {
        "project":   { "key": os.environ['JIRA_PROJECT'] },
        "summary":   os.environ['SUMMARY'],
        "issuetype": { "id": os.environ['ISSUE_TYPE_ID'] },
        "priority":  { "name": os.environ['PRIORITY'] },
        "labels":    ["tgd", os.environ['FEATURE_NAME']],
        "description": os.environ['DESCRIPTION']
    }
}

# Add any custom required fields discovered in Step 2
# payload['fields']['customfield_XXXX'] = { "value": user_provided_value }

print(json.dumps(payload))
EOF

# 3. Execute the API call
curl -x "" -s -X POST \
  "$JIRA_URL/rest/api/2/issue" \
  -H "Authorization: Bearer $JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/jira_payload.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('key','ERROR: '+d.get('errorMessages',str(d))[0]))"
```

### 💉 Custom Field Injection Reference

Mandatory fields vary by company and project. When a field is required, inject it into the JSON payload using the correct data type:

```json
// Dropdown / Select List (Single Choice)
"customfield_10100": { "value": "High" },

// Component/s (Multi-select)
"components": [{ "name": "Backend" }, { "name": "Database" }],

// Fix Version/s (Multi-select)
"fixVersions": [{ "name": "v1.2.0" }],

// Epic Link / Parent (String)
"customfield_10011": "PROJ-1001",

// User Picker (Single User)
"customfield_10300": { "name": "elon.wang" },

// Text / Text Area (String)
"customfield_10400": "Some internal notes here.",

// Labels
"labels": ["tgd", "jwt-auth", "urgent"]
```
> ⚠️ **Warning:** The `schema.type` returned by `createmeta` determines the structure. 
> *   `option` → `{ "value": "..." }`
> *   `array` → `[{ "name": "..." }]`
> *   `string` → `"..."` directly.

#### 🏆 Golden Example

**Scenario:** `feature-name` = `jwt-auth`, Task = "Implement Login API"

```json
{
  "fields": {
    "project": { "key": "ENG" },
    "summary": "[jwt-auth] As a user, I want to login via email and password to access my dashboard",
    "issuetype": { "id": "10000" },
    "priority": { "name": "High" },
    "labels": ["tgd", "jwt-auth"],
    "description": "h3. Background\n{noformat}\nCurrently, the system has no authentication. All endpoints are public, causing data leakage risks.\n{noformat}\n\nh3. Goal\n{noformat}\nImplement a secure POST /login endpoint that validates credentials and returns a JWT token valid for 24 hours.\n{noformat}\n\nh3. Acceptance Criteria\n{noformat}\nAC-1.1:\nGiven a registered user with valid credentials\nWhen they POST to /api/login\nThen they receive a 200 OK with a JWT token in the body\n\nAC-1.2:\nGiven an unregistered user or wrong password\nWhen they POST to /api/login\nThen they receive 401 Unauthorized and no token\n{noformat}\n\nh3. Technical Notes\n{noformat}\nFiles:\n- src/auth/login.py\n- tests/test_login.py\n- config/settings.py (JWT_SECRET)\n{noformat}"
  }
}
```

> ⚠️ **Critical:** The `summary` must always start with `[<feature-name>]` and follow the "As a... I want... So that..." format where possible. Keep it under 255 characters.

**Output:** Print each created issue key (e.g. `ENG-1234`).

### Step 4: Error Handling

If an issue creation fails, the script should:
- **401/403**: Token expired or invalid → Stop and ask user to re-provide `JIRA_TOKEN`
- **400 (summary too long)**: Jira limit is 255 chars. Shorten the summary and retry.
- **400 (missing field)**: Print the error, re-check createmeta for required fields, ask user for value.
- **400 (invalid priority)**: Fetch valid priorities via `$JIRA_URL/rest/api/2/priority` and retry.
- **500**: Retry once with `sleep 1`, if still fails skip and continue
- Continue processing remaining tasks even if one fails

### Step 5: Report

Output a summary table:

```
| TASKS.md Task | Jira Key | Status |
|---------------|----------|--------|
| Task 1: xxx   | ENG-1234 | ✅ Created |
| Task 2: yyy   | ENG-1235 | ✅ Created |
| Task 3: zzz   | -        | ❌ Failed: ... |
```

## Automation Pattern (for /tgd-plan conditional)

In `/tgd-plan`, add as a conditional skill:

```markdown
**Conditional (apply when relevant):**
- User wants Jira tickets? → `tgd-jira-auto-sync`
  1. Ask for JIRA_URL, JIRA_PROJECT (必填), JIRA_TOKEN.
  2. Query `createmeta` once to discover issue types + required fields. Let user choose issue type (default: Story). If required custom fields have allowedValues, present options.
  3. Parse $TGD_DIR/<feature-name>/TASKS.md and create issues via REST API v2.
  4. Report created issue keys.
```

## Pitfalls

### Data Center API Versions

- **REST API v2** (`/rest/api/2/`) — works on all Data Center versions
- **REST API v3** (`/rest/api/3/`) — DC 8.0+, uses Atlassian Document Format (ADF) for description fields. If v3, description must be ADF JSON, not wiki markup
- **Recommendation:** Use v2 with wiki markup (`h3.`, `{noformat}`) — simpler and universally compatible

### Custom Fields

If the company Jira has **required custom fields** (e.g., Component, Fix Version, Severity), the create payload must include them:

```json
"customfield_10100": {"value": "High"},
"components": [{"name": "Backend"}]
```

**How to discover:** Step 2's createmeta already includes all required fields and allowedValues. Use that result directly.

### SSL / Proxy Interception

Company MITM proxies cause `SSL certificate problem`. Solutions:
1. Set `REQUESTS_CA_BUNDLE` or `CURL_CA_BUNDLE` to the company CA cert path — this is the only acceptable fix.
2. Never disable verification (`curl -k`, `NODE_TLS_REJECT_UNAUTHORIZED=0`): the request carries your Jira PAT.

### Rate Limiting

Data Center may throttle bulk creation. If creating 20+ issues:
- Add `sleep 0.5` between API calls
- Or batch via `/rest/batch/1.0/issue` (if available on DC 9.0+)

## When to Use

- When `/tgd-plan` generates `TASKS.md`
- When user wants to sync tasks to Jira Data Center
- When planning sprint backlog from task breakdown

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll sync to Jira later" | Later never comes. Sync immediately after plan. |
| "Manual Jira entry is fine" | Manual entry loses the link between TASKS.md and Jira. |

## Red Flags

- Tasks created in Jira without corresponding TASKS.md entries
- Jira issues missing acceptance criteria from TASKS.md
- Sync run without user confirmation

## Verification

After execution, verify:
- [ ] All tasks from TASKS.md have corresponding Jira keys
- [ ] No creation errors in the report
- [ ] Created issues are viewable in Jira UI
