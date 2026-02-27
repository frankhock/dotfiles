---
name: factory-review-dimensions
description: >
  Review dimensions and checklists used by the factory reviewer.
  Not user-invocable — preloaded into the factory-reviewer sub-agent.
user-invocable: false
disable-model-invocation: true
---

# Review Dimensions

Use this checklist for every review. Not every dimension applies to every diff —
use judgment about which are relevant. But always at least consider each one.

## 1. Correctness

- Does the code do what the task asked for?
- Are all code paths handled (happy path + error paths)?
- Are return values correct in all cases?
- Are comparisons correct (off-by-one, boundary conditions, operator choice)?
- Are async operations properly awaited?
- Are resources properly cleaned up (connections, file handles, listeners)?

## 2. Security

- Is user input validated and sanitized before use?
- Are there SQL injection, XSS, or command injection vectors?
- Are secrets, API keys, or credentials hardcoded or logged?
- Are authentication/authorization checks present where needed?
- Are cryptographic operations using current, secure algorithms?
- Is sensitive data exposed in error messages or logs?
- Are dependencies pinned and free of known vulnerabilities?

## 3. Edge Cases

- What happens with null, undefined, empty string, empty array, zero?
- What happens with very large inputs?
- What happens with concurrent access or race conditions?
- What happens when external services are unavailable?
- Are timeouts configured for network operations?
- Are retry mechanisms safe (idempotent operations only)?

## 4. Architecture

- Does this change respect module boundaries?
- Does the dependency direction make sense (no circular deps, no reaching up)?
- Is the abstraction level consistent within the module?
- Are new dependencies justified?
- Does this follow the project's established patterns for similar features?
- Would this be easy to modify or extend in the future?

## 5. Test Quality

- Do tests verify behavior, not implementation details?
- Are failure cases tested, not just happy paths?
- Are edge cases from dimension 3 covered?
- Are tests independent (no shared mutable state between tests)?
- Do test names describe the scenario and expected outcome?
- Is there meaningful assertion (not just "doesn't throw")?
- For async code, are race conditions in tests avoided?

## 6. Consistency

- Does the naming match the rest of the codebase?
- Does the error handling pattern match the module's convention?
- Does the file organization follow the project structure?
- Are similar problems solved the same way as elsewhere in the codebase?
- Do new API endpoints follow the existing API conventions?

## 7. Completeness

- Is anything missing that the task implicitly requires?
- Are new public APIs documented (if the project convention requires it)?
- Are database migrations included if the schema changed?
- Are environment variables documented if new ones were added?
- Are feature flags or configuration options documented?
- Is logging sufficient for production debugging?
