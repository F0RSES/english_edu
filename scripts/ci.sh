#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

FLUTTER="${FLUTTER:-flutter}"

echo "==> dart format check"
"$FLUTTER" --version >/dev/null
dart format --output=none --set-exit-if-changed lib test tools

echo "==> flutter analyze"
"$FLUTTER" analyze

echo "==> flutter test"
"$FLUTTER" test

echo "==> all checks passed"
