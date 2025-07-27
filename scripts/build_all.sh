#!/bin/bash

# ONIS5 Build Script
# Builds all applications and libraries in the ONIS5 project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🏗️  ONIS5 Build Script${NC}"
echo "=================================="
echo "Project root: $PROJECT_ROOT"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows";;
        *)          echo "unknown";;
    esac
}

OS=$(detect_os)
echo "Detected OS: $OS"

# Build shared C++ libraries
build_shared_libs() {
    echo ""
    echo -e "${BLUE}📚 Building shared C++ libraries...${NC}"
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d "build" ]; then
        mkdir build
    fi
    
    cd build
    
    # Configure with CMake
    cmake .. -DCMAKE_BUILD_TYPE=Release
    
    # Build ONIS Core library
    make onis_core -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    print_status "Shared C++ libraries built successfully"
}

# Build ONIS Viewer (Flutter)
build_onis_viewer() {
    echo ""
    echo -e "${BLUE}📱 Building ONIS Viewer (Flutter)...${NC}"
    
    cd "$PROJECT_ROOT/apps/onis_viewer"
    
    # Get Flutter dependencies
    flutter pub get
    
    # Build for detected platform
    case $OS in
        "macos")
            flutter build macos --release
            print_status "ONIS Viewer built for macOS"
            ;;
        "linux")
            flutter build linux --release
            print_status "ONIS Viewer built for Linux"
            ;;
        "windows")
            flutter build windows --release
            print_status "ONIS Viewer built for Windows"
            ;;
        *)
            print_warning "Unknown OS, building for all platforms"
            flutter build macos --release
            flutter build linux --release
            flutter build windows --release
            ;;
    esac
}

# Build ONIS Site Server (C++)
build_onis_site_server() {
    echo ""
    echo -e "${BLUE}🖥️  Building ONIS Site Server (C++)...${NC}"
    
    cd "$PROJECT_ROOT/apps/onis_site_server"
    
    if [ ! -d "build" ]; then
        mkdir build
    fi
    
    cd build
    
    # Configure with CMake
    cmake .. -DCMAKE_BUILD_TYPE=Release
    
    # Build server
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    print_status "ONIS Site Server built successfully"
}

# Main build function
main() {
    echo "Starting build process..."
    
    # Check prerequisites
    if ! command -v cmake &> /dev/null; then
        print_error "CMake is required but not installed"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        print_warning "Flutter not found, skipping Flutter builds"
        SKIP_FLUTTER=true
    fi
    
    # Build shared libraries first
    build_shared_libs
    
    # Build applications
    if [ "$SKIP_FLUTTER" != "true" ]; then
        build_onis_viewer
    fi
    
    build_onis_site_server
    
    echo ""
    echo -e "${GREEN}🎉 All builds completed successfully!${NC}"
    echo ""
    echo "Build outputs:"
    echo "  - Shared libraries: $PROJECT_ROOT/build/lib/"
    echo "  - ONIS Viewer: $PROJECT_ROOT/apps/onis_viewer/build/"
    echo "  - ONIS Site Server: $PROJECT_ROOT/apps/onis_site_server/build/"
}

# Run main function
main "$@" 