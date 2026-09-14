#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gate="$script_dir/release_pr_gate.sh"

assert_gate() {
  local name="$1"
  local expected="$2"
  local fixture="$3"
  local actual

  actual="$(printf '%s' "$fixture" | RELEASE_BASE_REF=main "$gate")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Fehlgeschlagen: %s\nErwartet: %s\nErhalten: %s\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_gate \
  'Release-Branch mit beliebigem PR-Titel' \
  '{"number":12,"title":"Build ausprobieren","merged_at":"2026-09-14T08:00:00Z","base":{"ref":"main"},"head":{"ref":"release/2026.09.14-151"}}' \
  '[{"number":12,"title":"Build ausprobieren","merged_at":"2026-09-14T08:00:00Z","base":{"ref":"main"},"head":{"ref":"release/2026.09.14-151"}}]'

assert_gate \
  'Release-Branch unabhängig von Großschreibung' \
  '{"number":13,"title":"Noch ein Versuch","merged_at":"2026-09-14T09:00:00Z","base":{"ref":"main"},"head":{"ref":"Release/2026.09.14-152"}}' \
  '[{"number":13,"title":"Noch ein Versuch","merged_at":"2026-09-14T09:00:00Z","base":{"ref":"main"},"head":{"ref":"Release/2026.09.14-152"}}]'

assert_gate \
  'offener PR aus Release-Branch' \
  'null' \
  '[{"number":14,"title":"Egal","merged_at":null,"base":{"ref":"main"},"head":{"ref":"release/2026.09.14-153"}}]'

assert_gate \
  'Release-Titel aus normalem Branch' \
  'null' \
  '[{"number":15,"title":"Release 2026.09.14","merged_at":"2026-09-14T10:00:00Z","base":{"ref":"main"},"head":{"ref":"feature/login"}}]'

assert_gate \
  'ähnlicher Branch ohne Release-Prefix' \
  'null' \
  '[{"number":16,"title":"Release Candidate","merged_at":"2026-09-14T10:30:00Z","base":{"ref":"main"},"head":{"ref":"release-candidate/151"}}]'

assert_gate \
  'Release in anderen Basisbranch' \
  'null' \
  '[{"number":17,"title":"Beliebig","merged_at":"2026-09-14T11:00:00Z","base":{"ref":"develop"},"head":{"ref":"release/2026.09.14-154"}}]'

assert_gate \
  'neuesten passenden Merge auswählen' \
  '{"number":19,"title":"Zweiter Stand","merged_at":"2026-09-14T13:00:00Z","base":{"ref":"main"},"head":{"ref":"release/2026.09.14-156"}}' \
  '[{"number":18,"title":"Erster Stand","merged_at":"2026-09-14T12:00:00Z","base":{"ref":"main"},"head":{"ref":"release/2026.09.14-155"}},{"number":19,"title":"Zweiter Stand","merged_at":"2026-09-14T13:00:00Z","base":{"ref":"main"},"head":{"ref":"release/2026.09.14-156"}}]'

if printf 'kein json' | "$gate" >/dev/null 2>&1; then
  printf 'Fehlgeschlagen: Ungültiges JSON wurde akzeptiert.\n' >&2
  exit 1
fi

printf 'Release-PR-Gate: alle Tests erfolgreich.\n'
