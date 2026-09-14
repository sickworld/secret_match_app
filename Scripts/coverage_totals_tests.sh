#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
coverage_totals="$script_dir/coverage_totals.sh"

fixture='{
  "targets": [{
    "name": "SecretMatch.app",
    "coveredLines": 7,
    "executableLines": 11,
    "files": [
      {"path": "/repo/SecretMatch/Service/APIService.swift", "coveredLines": 6, "executableLines": 6},
      {"path": "/repo/SecretMatch/Views/LoginView.swift", "coveredLines": 1, "executableLines": 4},
      {"path": "/repo/SecretMatch/Components/Card.swift", "coveredLines": 0, "executableLines": 1}
    ]
  }]
}'

actual="$(printf '%s' "$fixture" | "$coverage_totals")"
expected=$'7\t11\t6\t6'
if [[ "$actual" != "$expected" ]]; then
  printf 'Coverage-Summen falsch. Erwartet: %q, erhalten: %q\n' "$expected" "$actual" >&2
  exit 1
fi

if printf '%s' "$fixture" | COVERAGE_TARGET_NAME=Missing.app "$coverage_totals" >/dev/null 2>&1; then
  echo 'Fehlgeschlagen: Ein fehlendes Coverage-Target wurde akzeptiert.' >&2
  exit 1
fi

if printf 'kein json' | "$coverage_totals" >/dev/null 2>&1; then
  echo 'Fehlgeschlagen: Ungültiges Coverage-JSON wurde akzeptiert.' >&2
  exit 1
fi

echo 'Coverage-Auswertung: alle Tests erfolgreich.'
