---
name: secretmatch-review
description: Review SecretMatch changes for bugs, regressions, security, privacy, Swift concurrency, SwiftUI behavior, API correctness, Xcode configuration risk, and release readiness. Use for explicit code reviews, diff or PR reviews, pre-commit review, pre-push verification, or the mandatory final review after implementing app changes.
---

# SecretMatch Review

Apply `../agent.md` first. Review only; do not implement fixes unless the user also asks for them.

## Establish scope

Run:

```bash
git status --short
git diff
git diff --cached
```

Distinguish task changes from pre-existing user changes. Inspect the complete affected functions and their callers; do not review only isolated diff lines.

## Review priorities

Check in this order:

1. Correctness and regressions in login, match, action, navigation, logout, and admin behavior.
2. Security and privacy: admin separation, input encoding, untrusted server data, credentials, sensitive logs, and accidental data exposure.
3. Async behavior: main-actor isolation, task lifetime, cancellation, duplicate submission, races, and state changes after navigation.
4. API contract: URL construction, method, content type, percent encoding, status codes, decoding, and error mapping.
5. SwiftUI UX: loading, empty, success and error states; iPad layout; accessibility; destructive action confirmation.
6. Xcode configuration: signing, bundle ID, team, deployment target, target membership, device family, and untracked user files.
7. Maintainability: unnecessary duplication, dead code, misleading names, and divergence from existing components.

Treat an issue as a finding only when it is specific, reproducible from the code, and materially useful to fix.

## Validate evidence

For app or project changes run:

```bash
xcodebuild -project SecretMatch.xcodeproj -scheme SecretMatch -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff --check
```

Inspect changed assets and project-file references when relevant. Do not claim runtime behavior was tested unless it was actually exercised.

## Report

Lead with findings ordered by severity. For each finding include:

- severity
- precise file and line
- concrete failure scenario or impact
- concise fix direction

Then list assumptions or open questions. End with a short validation summary.

If no findings exist, say so explicitly and mention residual risks such as missing automated tests or unexercised server behavior. Do not hide a clean review behind a long summary.
