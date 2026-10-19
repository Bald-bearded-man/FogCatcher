#!/usr/bin/env bash
# FogCatcher quality gate. CI runs this same script.
# Usage: scripts/ci-local.sh [--quick] [-h|--help]
#   --quick  skip the release build and Android lint
# Env: BUILD_NUMBER (default 1) sets the release versionCode; DEBUG_PIN_SHA256 enables the debug menu.
set -euo pipefail
FLUTTER_VERSION=3.44.3
QUICK=0
for a in "$@"; do case "$a" in --quick) QUICK=1;; -h|--help) sed -n '2,5p' "$0"; exit 0;; *) sed -n '2,5p' "$0"; exit 1;; esac; done
cd "$(dirname "$0")/.."
actual=$(flutter --version --machine | python3 -c 'import json,sys;print(json.load(sys.stdin)["frameworkVersion"])')
[ "$actual" = "$FLUTTER_VERSION" ] || { echo "Flutter $actual != pinned $FLUTTER_VERSION"; exit 1; }
flutter pub get
flutter gen-l10n
git diff --exit-code -- lib/l10n/generated || { echo "gen-l10n output is stale"; exit 1; }
[ -z "$(git ls-files --others --exclude-standard -- lib/l10n/generated)" ] || { echo "gen-l10n output is untracked"; exit 1; }
dart run tool/apply_pack.dart --check
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos
dart run dart_code_linter:metrics analyze lib --cyclomatic-complexity=15 --maximum-nesting-level=5 --number-of-parameters=6 --source-lines-of-code=80 --fatal-style --fatal-warnings
flutter test --coverage
python3 scripts/test_coverage_gate.py
python3 scripts/coverage_gate.py coverage/lcov.info lib/game=90 lib/services=70 lib=60
if [ "$QUICK" = 0 ]; then
  BUILD_NUMBER=${BUILD_NUMBER:-1}
  flutter build appbundle --release --build-number "$BUILD_NUMBER" --build-name "1.0.$BUILD_NUMBER" \
    --dart-define=APP_VERSION="1.0.$BUILD_NUMBER+$BUILD_NUMBER" \
    --dart-define=DEBUG_PIN_SHA256="${DEBUG_PIN_SHA256:-}"
  (cd android && ./gradlew :app:lintRelease)
fi
echo "GATE OK"
