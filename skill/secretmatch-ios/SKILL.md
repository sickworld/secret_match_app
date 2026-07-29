---
name: secretmatch-ios
description: Build, change, debug, or document the SecretMatch native iPad app. Use for SwiftUI views, observable state, APIService requests, Codable models, app assets, Xcode project settings, login, match/action flows, admin screens, and user-facing iOS behavior in this repository.
---

# SecretMatch iOS

Apply `../agent.md` first, then follow this skill.

## Understand the change

Inspect the affected view, its models, and `APIService` together. Trace the complete user path including loading, success, empty, and error states before editing.

Preserve the current structure:

- SwiftUI views in `SecretMatch/Views`
- shared UI in `SecretMatch/Components`
- network behavior in `SecretMatch/Service/APIService.swift`
- response and domain types in `SecretMatch/Objects`

## Implement safely

- Keep view state local unless multiple screens genuinely share it.
- Keep observable UI mutations on the main actor.
- Avoid detached unstructured tasks and duplicate requests caused by repeated view appearance.
- Encode form data with `URLComponents`/`URLQueryItem` or another correct percent-encoding mechanism.
- Use `JSONEncoder` for JSON payloads when a typed request model is practical.
- Check HTTP status before decoding and map failures to safe, understandable app errors.
- Never log complete API responses, passwords, event numbers, tokens, or admin data.
- Keep admin navigation and data separate from regular user state.
- Normalize event numbers in one consistent place and verify edge cases before changing normalization.

## Maintain the UI

- Reuse `SecretMatchTheme`, `BrandBackground`, and existing controls where suitable.
- Design for iPad and dark appearance.
- Preserve accessible labels, readable contrast, touch target sizes, and Dynamic Type behavior.
- Provide visible progress for async actions and prevent accidental double submission.
- Make empty and failure states actionable in ordinary language.

## Handle project settings

Treat changes to bundle identifier, development team, signing, capabilities, deployment target, and device family as high risk. Change them only when the task requires it and call them out in the final response.

Do not add or commit `xcuserdata`, breakpoints, or `UserInterfaceState.xcuserstate`.

## Validate

Review the final diff with `../secretmatch-review/SKILL.md`.

For code or Xcode project changes run:

```bash
xcodebuild -project SecretMatch.xcodeproj -scheme SecretMatch -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff --check
```

Report compilation as a build check, not as behavioral test coverage.
