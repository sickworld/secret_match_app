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
  'exakter Release-Titel' \
  '{"number":12,"title":"release","merged_at":"2026-09-14T08:00:00Z","base":{"ref":"main"}}' \
  '[{"number":12,"title":"release","merged_at":"2026-09-14T08:00:00Z","base":{"ref":"main"}}]'

assert_gate \
  'Release-Titel mit Versionszusatz' \
  '{"number":13,"title":"Release: 2026.09.14","merged_at":"2026-09-14T09:00:00Z","base":{"ref":"main"}}' \
  '[{"number":13,"title":"Release: 2026.09.14","merged_at":"2026-09-14T09:00:00Z","base":{"ref":"main"}}]'

assert_gate \
  'offener Release-PR' \
  'null' \
  '[{"number":14,"title":"release","merged_at":null,"base":{"ref":"main"}}]'

assert_gate \
  'normaler gemergter PR' \
  'null' \
  '[{"number":15,"title":"Improve login","merged_at":"2026-09-14T10:00:00Z","base":{"ref":"main"}}]'

assert_gate \
  'Release-ähnlicher Titel ohne Freigabeformat' \
  'null' \
  '[{"number":16,"title":"release candidate","merged_at":"2026-09-14T10:30:00Z","base":{"ref":"main"}}]'

assert_gate \
  'Release in anderen Basisbranch' \
  'null' \
  '[{"number":17,"title":"release","merged_at":"2026-09-14T11:00:00Z","base":{"ref":"develop"}}]'

assert_gate \
  'neuesten passenden Merge auswählen' \
  '{"number":19,"title":"Release: 150","merged_at":"2026-09-14T13:00:00Z","base":{"ref":"main"}}' \
  '[{"number":18,"title":"release","merged_at":"2026-09-14T12:00:00Z","base":{"ref":"main"}},{"number":19,"title":"Release: 150","merged_at":"2026-09-14T13:00:00Z","base":{"ref":"main"}}]'

if printf 'kein json' | "$gate" >/dev/null 2>&1; then
  printf 'Fehlgeschlagen: Ungültiges JSON wurde akzeptiert.\n' >&2
  exit 1
fi

printf 'Release-PR-Gate: alle Tests erfolgreich.\n'
