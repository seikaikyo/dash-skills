# FFUF Web Fuzzing

Expert guidance for ffuf web fuzzing during authorized penetration testing.

## Installation

```
/plugin install trailofbits/skills-curated/plugins/ffuf-web-fuzzing
```

## Prerequisites

[ffuf](https://github.com/ffuf/ffuf) must be installed:

```bash
brew install ffuf          # macOS
go install github.com/ffuf/ffuf/v2@latest  # Go
```

## Usage

The skill activates when you're working on web fuzzing tasks. Ask Claude to:

- Fuzz directories and files on a target
- Enumerate subdomains
- Discover API endpoints
- Build authenticated fuzzing campaigns with raw requests
- Analyze ffuf JSON output for anomalies

## Example

```
> Fuzz the /api endpoint on staging.example.com for hidden paths

Claude runs:
  ffuf -w /opt/SecLists/Discovery/Web-Content/api/api-endpoints.txt \
       -u https://staging.example.com/api/FUZZ \
       -ac -c -v -o results.json

Then analyzes the results, highlighting anomalous status codes,
size outliers, and interesting endpoint names.
```

## What It Covers

- **Core fuzzing** -- directory/file discovery, subdomain enumeration, parameter fuzzing
- **Authenticated fuzzing** -- raw request templates for JWT, OAuth, cookies, API keys
- **Auto-calibration** -- why `-ac` is mandatory and how it works
- **Result analysis** -- guidance for identifying anomalies in JSON output
- **Wordlist selection** -- which SecLists wordlist for which scenario
- **Rate limiting** -- appropriate settings for production vs. staging vs. lab

## Safety

This skill is for authorized security testing only. It includes rate limiting guidance and encourages responsible testing practices. Only use against systems you own or have explicit written permission to test.

## Credits

Original skill by [jthack/ffuf_claude_skill](https://github.com/jthack/ffuf_claude_skill). Restructured for the Trail of Bits curated skills marketplace.
