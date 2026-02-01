#!/bin/bash

# Build script for ONIS Site Server
# Uses the unified build directory at the project root
set -e

echo "🔨 Building ONIS Site Server..."

# Get the project root (parent of apps/onis_site_server)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Create build directory at root
cd "$PROJECT_ROOT"
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# Configure and build
echo "📋 Configuring CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "🔨 Building onis_site_server..."
make onis_site_server -j$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

echo "✅ ONIS Site Server build complete!"
echo "🎯 You can run it with: $PROJECT_ROOT/build/bin/onis_site_server" 