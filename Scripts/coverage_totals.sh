#!/usr/bin/env bash

set -euo pipefail

report_path="${1:-/dev/stdin}"
target_name="${COVERAGE_TARGET_NAME:-SecretMatch.app}"

jq -er --arg target_name "$target_name" '
  [.targets[] | select(.name == $target_name)]
  | if length != 1 then
      error("Coverage target not found or ambiguous: " + $target_name)
    else
      .[0] as $target
      | [
          $target.coveredLines,
          $target.executableLines,
          ([
            $target.files[]
            | select((.path | contains("/Views/")) | not)
            | select((.path | contains("/Components/")) | not)
            | .coveredLines
          ] | add // 0),
          ([
            $target.files[]
            | select((.path | contains("/Views/")) | not)
            | select((.path | contains("/Components/")) | not)
            | .executableLines
          ] | add // 0)
        ]
      | @tsv
    end
' "$report_path"
