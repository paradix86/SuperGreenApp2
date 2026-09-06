#!/usr/bin/env bash
set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD=(flutter)
elif command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD=(fvm flutter)
else
  echo "Neither flutter nor fvm was found in PATH. Install Flutter 3.7.12 or fvm."
  exit 1
fi

if [ ! -f ".env" ]; then
  echo ".env not found. Copy .env.example to .env and fill the required values."
  exit 1
fi

echo "Installing Dart/Flutter packages..."
"${FLUTTER_CMD[@]}" pub get

echo "Running code generation..."
"${FLUTTER_CMD[@]}" pub run build_runner build --delete-conflicting-outputs

echo "Bootstrap completed."
