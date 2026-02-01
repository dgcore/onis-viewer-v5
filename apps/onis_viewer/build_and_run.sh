#!/bin/bash

# Build and run script for ONIS Viewer
set -e

echo "🚀 Building and running ONIS Viewer..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build native library first
echo "🔨 Step 1: Building native C++ library..."
./macos/build_native.sh

# Build Flutter app
echo "📱 Step 2: Building Flutter app..."
flutter clean
flutter pub get
flutter build macos --debug

# Copy native library to app bundle
echo "📦 Step 3: Copying native library to app bundle..."
cp macos/build_native/libonis_core.dylib build/macos/Build/Products/Debug/onis_viewer.app/Contents/MacOS/

# Verify signing
echo "🔐 Step 4: Verifying code signing..."
codesign --verify --verbose=4 build/macos/Build/Products/Debug/onis_viewer.app/Contents/MacOS/libonis_core.dylib

echo "✅ Build complete! Starting the app..."
flutter run -d macos --scheme Runner 