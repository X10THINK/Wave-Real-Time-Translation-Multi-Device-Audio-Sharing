#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python -m pytest translation_gateway/gateway -q
if command -v kotlinc >/dev/null && command -v java >/dev/null; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  path='android/app/src/main/kotlin/com/x10think/wave'
  kotlinc "$path/TranslationCaptionWire.kt" tools/TranslationCaptionWireTest.kt -include-runtime -d "$tmp/captions.jar"
  java -jar "$tmp/captions.jar"
fi
if command -v flutter >/dev/null; then
  flutter pub get
  flutter analyze
  flutter test
else
  echo 'Flutter unavailable: Dart/Android compilation and Flutter tests NOT RUN.'
fi
