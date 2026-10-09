#!/usr/bin/env bash
# Сборка веб-версии для Vercel (vercel.json → buildCommand).
# В образе Vercel нет Flutter, поэтому ставим ту же версию, что и в CI
# (.github/workflows/ci.yml), и собираем build/web — его Vercel и выкладывает.
# Без этого каждый коммит в main выкладывал голый репозиторий и сайт отдавал 404.
set -euo pipefail

FLUTTER_VERSION="3.47.5"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

# Flutter распаковывает Dart SDK через unzip, а в образе Vercel его может не быть.
if ! command -v unzip >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y unzip >/dev/null
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq unzip >/dev/null
  fi
fi

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter --version
flutter pub get
flutter build web --release
