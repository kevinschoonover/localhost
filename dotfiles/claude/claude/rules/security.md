---
paths:
  - "**/*.{ts,tsx,js,jsx}"
  - ".github/workflows/**"
  - "**/Dockerfile*"
---
# Security

- Never log secrets, tokens, salts, or PII — including in Sentry context, error messages, and CI output.
- User- or payload-supplied URLs: validate and allowlist before fetching (SSRF, credential exfiltration).
- Escape/encode user data in generated HTML (XSS) and constructed URLs/connection strings.
- Docker: no secrets in image layers or persisted build args; run as non-root.
- Validate input at trust boundaries. A type assertion is not validation.
- Never spread an entity into a response or a log — enumerate the fields you intend to expose. Over-disclosure at a serialization boundary is how PHI leaks.
- Supply chain: `npm ci --ignore-scripts` in CI; lockfile changes get reviewed.
