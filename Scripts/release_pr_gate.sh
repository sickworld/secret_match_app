#!/usr/bin/env bash

set -euo pipefail

base_ref="${RELEASE_BASE_REF:-main}"

jq -c --arg base_ref "$base_ref" '
  [
    .[]
    | select(.merged_at != null)
    | select(.base.ref == $base_ref)
    | select(.title | test("^release(: .+)?$"; "i"))
  ]
  | sort_by(.merged_at)
  | last // null
'
