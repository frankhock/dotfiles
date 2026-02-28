# Security Specialist

Performs security review for vulnerabilities, input validation, authentication/authorization, and data protection.

## Input Validation

- All controller params use strong parameters (`permit`)?
- Type validation, length limits, and format constraints applied?
- File uploads validated (type, size, content)?
- No user input interpolated into SQL, shell commands, or rendered HTML?

## Injection Vectors

### SQL Injection
- No string interpolation in `where` clauses or raw SQL?
- All dynamic values use parameterized queries or ActiveRecord sanitization?
- `find_by_sql`, `execute`, `connection.select_all` use bind parameters?

### XSS
- User content escaped in views (Rails auto-escapes, but check for `raw`, `html_safe`, `safe_join`)?
- `dangerouslySetInnerHTML` in React used only with sanitized content?
- Content Security Policy headers configured?

### Command Injection
- No user input in `system()`, backticks, `exec`, `Open3`, or `Kernel.send`?
- File paths from user input sanitized against traversal (`../`)?

## Authentication & Authorization

- All endpoints require authentication unless explicitly public?
- Authorization checks at the resource level, not just route level?
- `current_user` scoping prevents accessing other users' data?
- Admin/staff-only actions properly gated?
- Session management secure (secure cookies, expiration, rotation)?
- Password reset and email change flows protected against account takeover?

## Secrets & Credentials

- No hardcoded API keys, passwords, tokens, or secrets in code?
- Secrets loaded from environment variables or encrypted credentials?
- Sensitive data not logged (passwords, tokens, PII)?
- `.env` files and credential files in `.gitignore`?

## Data Protection

- PII identified and handled appropriately?
- Sensitive fields encrypted at rest where required?
- Error messages don't leak internal state, stack traces, or user data?
- API responses don't over-expose fields (check serializers)?
- Audit trails for sensitive data access where appropriate?

## Rails-Specific Checks

- `protect_from_forgery` (CSRF) enabled?
- Mass assignment protection via strong parameters?
- `redirect_to` not using user-controlled URLs without allowlisting?
- `send_file` / `send_data` paths validated?
- Callbacks and filters not bypassable via unexpected params?

## React/Frontend-Specific Checks

- No secrets in client-side code or environment variables prefixed with `NEXT_PUBLIC_` / `REACT_APP_`?
- OAuth tokens stored securely (not localStorage for sensitive tokens)?
- API calls include proper CORS and authentication headers?
