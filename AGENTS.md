# Agent Instructions for SecretMatch

Follow `skill/agent.md` for every task in this repository. Treat it as mandatory project policy.

Load the matching project skill when the task touches its area:

- `skill/secretmatch-ios/SKILL.md` for SwiftUI, app behavior, API integration, models, assets, or Xcode project changes.
- `skill/secretmatch-review/SKILL.md` for reviews, pre-commit checks, regression analysis, and release-readiness checks.

## Non-Negotiable Workflow

- Complete the requested task end-to-end unless the user asks only for analysis, a plan, or a review.
- Before editing, inspect the relevant code and run `git status --short`.
- Preserve existing user changes and never revert unrelated work.
- Keep changes small, thematic, and consistent with the existing SwiftUI architecture.
- Review every completed code change before delivery.
- Run the smallest relevant checks; for app changes, build the `SecretMatch` scheme.
- Run `git diff --check` before committing.
- Stage only task-related files and exclude Xcode user-state files.
- Commit with a clear product-level message and push the current branch unless the user explicitly says not to.
- Never commit credentials, passwords, tokens, signing material, or local Xcode state.
- If review, build, commit, or push cannot be completed, report the exact blocker and next action.

## Final Response

Always include:

- what changed
- review result and any remaining risks
- tests/checks run
- commit hash
- push result
- whether the working tree is clean, including unrelated pre-existing changes
