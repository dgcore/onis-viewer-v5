#!/bin/bash

# ONIS Viewer development environment setup script
# Automatically configures all code quality tools

set -e

echo "🚀 Setting up ONIS Viewer development environment..."
echo "================================================================"

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display errors
error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Function to display success
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to display warnings
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to display information
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Detect operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PACKAGE_MANAGER="brew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    else
        error "Unsupported package manager"
    fi
else
    error "Unsupported operating system: $OSTYPE"
fi

echo ""
info "Detected system: $OS ($PACKAGE_MANAGER)"

# 1. Check/Install Flutter
echo ""
info "Checking Flutter..."
if command -v flutter &> /dev/null; then
    success "Flutter already installed"
    flutter --version
else
    warning "Flutter not found"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    echo "Then re-run this script"
    exit 1
fi

# 2. Check/Install Dart
echo ""
info "Checking Dart..."
if command -v dart &> /dev/null; then
    success "Dart already installed"
    dart --version
else
    warning "Dart not found"
    echo "Please install Dart or Flutter (which includes Dart)"
    exit 1
fi

# 3. Check/Install clang-format
echo ""
info "Checking clang-format..."
if command -v clang-format &> /dev/null; then
    success "clang-format already installed"
    clang-format --version
else
    warning "clang-format not found"
    if [ "$OS" = "macos" ]; then
        echo "Installing clang-format via Homebrew..."
        brew install clang-format
    elif [ "$OS" = "linux" ]; then
        if [ "$PACKAGE_MANAGER" = "apt" ]; then
            sudo apt-get update
            sudo apt-get install -y clang-format
        elif [ "$PACKAGE_MANAGER" = "yum" ]; then
            sudo yum install -y clang-tools-extra
        fi
    fi
    success "clang-format installed"
fi

# 4. Check/Install CMake
echo ""
info "Checking CMake..."
if command -v cmake &> /dev/null; then
    success "CMake already installed"
    cmake --version
else
    warning "CMake not found"
    if [ "$OS" = "macos" ]; then
        echo "Installing CMake via Homebrew..."
        brew install cmake
    elif [ "$OS" = "linux" ]; then
        if [ "$PACKAGE_MANAGER" = "apt" ]; then
            sudo apt-get install -y cmake
        elif [ "$PACKAGE_MANAGER" = "yum" ]; then
            sudo yum install -y cmake
        fi
    fi
    success "CMake installed"
fi

# 5. Check/Install Git
echo ""
info "Checking Git..."
if command -v git &> /dev/null; then
    success "Git already installed"
    git --version
else
    warning "Git not found"
    if [ "$OS" = "macos" ]; then
        echo "Installing Git via Homebrew..."
        brew install git
    elif [ "$OS" = "linux" ]; then
        if [ "$PACKAGE_MANAGER" = "apt" ]; then
            sudo apt-get install -y git
        elif [ "$PACKAGE_MANAGER" = "yum" ]; then
            sudo yum install -y git
        fi
    fi
    success "Git installed"
fi

# 6. Configure Git hooks
echo ""
info "Configuring Git hooks..."
if [ -d ".git" ]; then
    # Copy pre-commit script
    cp .infra/pre-commit-hooks.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    success "Git hooks configured"
else
    warning ".git directory not found - hooks ignored"
fi

# 7. Install Flutter dependencies
echo ""
info "Installing Flutter dependencies..."
flutter pub get
success "Flutter dependencies installed"

# 8. Check quality tools
echo ""
info "Checking quality tools..."
if [ -f ".infra/quality-check.sh" ]; then
    chmod +x .infra/quality-check.sh
    success "Quality check script configured"
else
    error "Quality check script missing"
fi

# 9. Configure VS Code (if present)
echo ""
info "Configuring VS Code..."
if command -v code &> /dev/null; then
    if [ -d ".vscode" ]; then
        success "VS Code configuration present"
        echo "Recommended extensions:"
        echo "  - Dart Code"
        echo "  - Flutter"
        echo "  - C/C++"
        echo "  - CMake Tools"
        echo "  - EditorConfig"
    else
        warning ".vscode directory missing"
    fi
else
    warning "VS Code not found - configuration ignored"
fi

# 10. Final test
echo ""
info "Final environment test..."
if ./.infra/quality-check.sh > /dev/null 2>&1; then
    success "Environment configured successfully!"
else
    warning "Some tests failed - check errors above"
fi

echo ""
success "🎉 Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Open the project in VS Code"
echo "2. Install recommended extensions"
echo "3. Run './.infra/quality-check.sh' to verify quality"
echo "4. Start developing!"
echo ""
echo "🔧 Useful commands:"
echo "  - './.infra/quality-check.sh' : Complete verification"
echo "  - 'dart format .' : Dart formatting"
echo "  - 'clang-format -i native/*.cpp native/*.h' : C++ formatting"
echo "  - 'flutter test' : Run tests"
echo "  - './build_all.sh' : Complete build" 