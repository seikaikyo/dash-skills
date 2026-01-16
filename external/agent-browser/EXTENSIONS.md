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
