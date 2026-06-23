# Security Policy

## Supported Versions

Only the current App Store release of Vitamin G receives security updates.

| Channel | Supported |
|---------|-----------|
| Current App Store release | ✅ |
| Previous major versions | ❌ |
| Beta / TestFlight builds | ✅ (during active testing) |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Email: **kileharrington@gmail.com**
Subject line: `[SECURITY] Vitamin G — <brief description>`

Include:
- A clear description of the vulnerability
- Steps to reproduce (device model, iOS version, app version)
- Potential impact
- Any proof-of-concept code or screenshots (if available)

You will receive an acknowledgement within **48 hours** and a status update within **7 days**. If the issue is confirmed, a fix will be prioritised for the next release. You will be credited in the release notes unless you prefer to remain anonymous.

## Scope

**In scope:**
- The Vitamin G iOS app (SwiftData local storage, CloudKit sync, authentication flow)
- The Cloudflare Worker AI proxy at `vg-ai-proxy.kileharrington.workers.dev`
- Community feed data (CloudKit public database posts, reactions, reports)

**Out of scope:**
- Apple's iCloud / CloudKit infrastructure
- Apple Sign In infrastructure
- Anthropic's Claude API
- Issues that require physical access to an already-unlocked device

## Disclosure Policy

This project follows coordinated disclosure. Please allow reasonable time to patch before any public disclosure. We aim to resolve critical issues within **14 days** and non-critical issues within **90 days**.
