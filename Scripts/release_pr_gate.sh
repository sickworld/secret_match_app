#!/usr/bin/env bash

set -euo pipefail

base_ref="${RELEASE_BASE_REF:-main}"
branch_prefix="${RELEASE_BRANCH_PREFIX:-release/}"

jq -c --arg base_ref "$base_ref" --arg branch_prefix "$branch_prefix" '
  ($branch_prefix | ascii_downcase) as $normalized_branch_prefix
  |
  [
    .[]
    | select(.merged_at != null)
    | select(.base.ref == $base_ref)
    | select(((.head.ref // "") | ascii_downcase) | startswith($normalized_branch_prefix))
  ]
  | sort_by(.merged_at)
  | last // null
'
