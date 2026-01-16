---
name: agent-browser
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.
source: https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/SKILL.md
updated: 2026-01-16 10:38:05
---

> **Reference**: https://github.com/vercel-labs/agent-browser
> **Official Skill**: https://raw.githubusercontent.com/vercel-labs/agent-browser/main/skills/agent-browser/SKILL.md

# Browser Automation with agent-browser

## Quick start

```bash
agent-browser open <url>        # Navigate to page
agent-browser snapshot -i       # Get interactive elements with refs
agent-browser click @e1         # Click element by ref
agent-browser fill @e2 "text"   # Fill input by ref
agent-browser close             # Close browser
```

## Core workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. Interact using refs from the snapshot
4. Re-snapshot after navigation or significant DOM changes

## Commands

### Navigation
```bash
agent-browser open <url>      # Navigate to URL
agent-browser back            # Go back
agent-browser forward         # Go forward  
agent-browser reload          # Reload page
agent-browser close           # Close browser
```

### Snapshot (page analysis)
```bash
agent-browser snapshot        # Full accessibility tree
agent-browser snapshot -i     # Interactive elements only (recommended)
agent-browser snapshot -c     # Compact output
agent-browser snapshot -d 3   # Limit depth to 3
```

### Interactions (use @refs from snapshot)
```bash
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
```

### Get information
```bash
agent-browser get text @e1        # Get element text
agent-browser get value @e1       # Get input value
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
```

### Screenshots
```bash
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page
```

### Wait
```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait milliseconds
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --load networkidle      # Wait for network idle
```

### Semantic locators (alternative to refs)
```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
```

## Example: Form submission

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# Output shows: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Check result
```

## Example: Authentication with saved state

```bash
# Login once
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later sessions: load saved state
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## Sessions (parallel browsers)

```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

## JSON output (for parsing)

Add `--json` for machine-readable output:
```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```

## Debugging

```bash
agent-browser open example.com --headed  # Show browser window
agent-browser console                    # View console messages
agent-browser errors                     # View page errors
```

---

## Advanced Features (Extensions)

> These features are supported by agent-browser CLI but not included in the official skill documentation.

### Focus element
```bash
agent-browser focus @e1           # Focus on element
```

### Drag and drop
```bash
agent-browser drag @e1 @e2        # Drag from @e1 to @e2
```

### File upload
```bash
agent-browser upload @e1 /path/to/file.pdf  # Upload file to input
```

### PDF export
```bash
agent-browser pdf output.pdf      # Export page as PDF
```

### Cookie management
```bash
agent-browser cookies             # Get all cookies (JSON)
agent-browser cookies set name value  # Set cookie
agent-browser cookies set name value --domain example.com --path /
agent-browser cookies clear       # Clear all cookies
```

### JavaScript execution
```bash
agent-browser evaluate "document.title"
agent-browser evaluate "localStorage.getItem('token')"
agent-browser evaluate "window.scrollTo(0, document.body.scrollHeight)"
```

### Network monitoring
```bash
agent-browser network             # Get network requests (JSON)
agent-browser network --json      # Structured output
```

### Session management
```bash
agent-browser session list        # List all sessions
agent-browser session kill test1  # Kill specific session
```

### Wait for URL pattern
```bash
agent-browser wait --url "**/dashboard"    # Wait for URL match
agent-browser wait --load domcontentloaded # Wait for DOM ready
agent-browser wait --load load             # Wait for page load
```

## Extended Examples

### Visual regression testing
```bash
agent-browser open https://example.com
agent-browser wait 2000
agent-browser screenshot before.png --full

# After changes
agent-browser reload
agent-browser wait 2000
agent-browser screenshot after.png --full
```

### File upload workflow
```bash
agent-browser open https://example.com/upload
agent-browser snapshot -i
agent-browser upload @e1 /path/to/document.pdf
agent-browser click @e2  # Submit button
```

### Multi-session testing
```bash
agent-browser --session admin open https://app.com/admin
agent-browser --session user open https://app.com/dashboard

# Admin actions
agent-browser --session admin snapshot -i
agent-browser --session admin click @e1

# User actions
agent-browser --session user snapshot -i
agent-browser --session user click @e2

# Cleanup
agent-browser session kill admin
agent-browser session kill user
```

### Custom JavaScript injection
```bash
agent-browser open https://example.com
agent-browser evaluate "localStorage.setItem('debug', 'true')"
agent-browser reload
agent-browser evaluate "document.querySelectorAll('a').length"
```

### Error monitoring
```bash
agent-browser open https://example.com
agent-browser wait 3000
agent-browser errors    # Check for JavaScript errors
agent-browser console   # View console output
```
