#!/bin/bash

# Build script for ONIS Site Server
set -e

echo "🔨 Building ONIS Site Server..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create build directory
mkdir -p build
cd build

# Configure and build
echo "📋 Configuring CMake..."
cmake ..

echo "🔨 Building..."
make -j$(sysctl -n hw.ncpu)

echo "✅ ONIS Site Server build complete!"
echo "🎯 You can run it with: ./build/onis_site_server" 