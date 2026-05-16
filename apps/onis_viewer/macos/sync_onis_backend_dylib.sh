#!/usr/bin/env bash
# Build libonis_backend from the ONIS5 repo root and copy it next to the
# Flutter macOS app so DynamicLibrary can load the DCMTK-enabled backend.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="${1:-$REPO_ROOT/build}"
CONFIG="${2:-Release}"

echo "Configuring / building onis_backend (CONFIG=$CONFIG) in $BUILD_DIR"
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$CONFIG"
cmake --build "$BUILD_DIR" --target onis_backend -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 8)"

DYLIB="$BUILD_DIR/lib/libonis_backend.dylib"
if [[ ! -f "$DYLIB" ]]; then
  echo "Expected $DYLIB — adjust BUILD_DIR if you use a different CMake binary dir."
  exit 1
fi

# Typical Flutter output layout (Debug); adjust if you use Profile/Release.
OUT_DIR="$SCRIPT_DIR/../build/macos/Build/Products/Debug/onis_viewer.app/Contents/MacOS"
if [[ -d "$OUT_DIR" ]]; then
  cp -f "$DYLIB" "$OUT_DIR/"
  echo "Copied to $OUT_DIR"
else
  echo "Flutter app bundle not found at $OUT_DIR"
  echo "Run 'flutter build macos --debug' (or run once) so the app exists, then re-run this script."
  echo "Or copy manually: cp $DYLIB <path-to-onis_viewer.app/Contents/MacOS/>"
  exit 2
fi
