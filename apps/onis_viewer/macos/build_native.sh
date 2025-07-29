#!/bin/bash

# Build script for ONIS Core native library on macOS
set -e

echo "🔨 Building ONIS Core native library for macOS..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_native"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "📋 Configuring CMake..."
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
      "$PROJECT_ROOT/shared/cpp/onis_core"

# Build the library
echo "🔨 Building library..."
make -j$(nproc)

# Code sign the library
echo "🔐 Code signing library..."
codesign --force --sign "Apple Development: Cedric Lemoigne (QQW5T8AY2C)" "libonis_core.dylib"

# Copy the library to the Flutter app bundle
echo "📦 Copying library to Flutter app bundle..."
FLUTTER_BUILD_DIR="$SCRIPT_DIR/../build/macos/Build/Products/Debug"
if [ -d "$FLUTTER_BUILD_DIR" ]; then
    cp "libonis_core.dylib" "$FLUTTER_BUILD_DIR/onis_viewer.app/Contents/MacOS/"
    echo "✅ Library copied to Flutter app bundle"
else
    echo "⚠️  Flutter build directory not found. Run 'flutter build macos --debug' first."
fi

echo "✅ ONIS Core native library build complete!" 