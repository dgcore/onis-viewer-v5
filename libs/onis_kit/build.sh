#!/bin/bash

# Build script for ONIS Kit library
set -e

echo "🔨 Building ONIS Kit library..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "📋 Configuring CMake..."
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
      ..

# Build the library
echo "🔨 Building library..."
make -j$(sysctl -n hw.ncpu)

# Code sign the library (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔐 Code signing library..."
    if command -v codesign &> /dev/null; then
        # Try to find a valid signing identity
        SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | cut -d'"' -f2)
        if [ -n "$SIGNING_IDENTITY" ]; then
            codesign --force --sign "$SIGNING_IDENTITY" "libonis_kit.dylib"
            echo "✅ Library code signed with: $SIGNING_IDENTITY"
        else
            echo "⚠️  No Apple Development identity found, skipping code signing"
        fi
    fi
fi

echo "✅ ONIS Kit library build complete!"
echo "📦 Library location: $BUILD_DIR/libonis_kit.dylib"
echo "📋 You can now link this library in your applications" 