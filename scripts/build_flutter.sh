#!/bin/bash

# Custom Flutter build script that uses a specific build directory
# Usage: ./scripts/build_flutter.sh [platform] [mode]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PLATFORM=${1:-macos}
MODE=${2:-debug}
BUILD_DIR="build_artifacts"

echo -e "${BLUE}🏗️  Building Flutter app for $PLATFORM in $MODE mode${NC}"
echo "Build directory: $BUILD_DIR"

# Navigate to Flutter app directory
cd apps/onis_viewer

# Clean previous build
echo "Cleaning previous build..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build with custom directory
echo "Building for $PLATFORM..."
export FLUTTER_BUILD_DIR=$BUILD_DIR
flutter build $PLATFORM --$MODE

# Clean up the root-level build directory if it was created
if [ -d "../onis_viewer" ]; then
    echo "Cleaning up root-level build directory..."
    rm -rf ../onis_viewer
fi

echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo "Build artifacts are in: apps/onis_viewer/$BUILD_DIR/" 