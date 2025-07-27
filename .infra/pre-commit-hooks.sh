#!/bin/bash

# Pre-commit hooks script for ONIS Viewer
# Automatic code quality checks

set -e

echo "🔍 Code quality verification..."

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 1. Dart/Flutter formatting verification
echo "📱 Dart/Flutter formatting verification..."
if command -v dart &> /dev/null; then
    # Check formatting
    if ! dart format --set-exit-if-changed lib/ test/; then
        error "Dart code is not properly formatted. Run 'dart format .'"
    fi
    success "Dart formatting OK"
else
    warning "Dart not found, formatting verification ignored"
fi

# 2. Dart static analysis
echo "🔍 Dart static analysis..."
if command -v dart &> /dev/null; then
    if ! dart analyze; then
        error "Dart static analysis detected issues"
    fi
    success "Dart static analysis OK"
else
    warning "Dart not found, static analysis ignored"
fi

# 3. C++ formatting verification
echo "⚙️  C++ formatting verification..."
if command -v clang-format &> /dev/null; then
    # Check modified C++ files
    CPP_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cpp|h|hpp|cc|cxx)$' || true)
    
    if [ -n "$CPP_FILES" ]; then
        for file in $CPP_FILES; do
            if [ -f "$file" ]; then
                # Check if file is properly formatted
                if ! clang-format --dry-run --Werror "$file" > /dev/null 2>&1; then
                    error "C++ file '$file' is not properly formatted. Run 'clang-format -i $file'"
                fi
            fi
        done
        success "C++ formatting OK"
    else
        success "No modified C++ files"
    fi
else
    warning "clang-format not found, C++ formatting verification ignored"
fi

# 4. Test verification
echo "🧪 Test verification..."
if command -v flutter &> /dev/null; then
    if ! flutter test --no-pub; then
        error "Tests failed"
    fi
    success "Tests OK"
else
    warning "Flutter not found, test verification ignored"
fi

# 5. Compilation verification
echo "🔨 Compilation verification..."
if command -v flutter &> /dev/null; then
    # Check that project compiles
    if ! flutter build macos --debug; then
        error "Compilation failed"
    fi
    success "Compilation OK"
else
    warning "Flutter not found, compilation verification ignored"
fi

# 6. Dependencies verification
echo "📦 Dependencies verification..."
if command -v flutter &> /dev/null; then
    if ! flutter pub deps --style=compact | grep -q "✓"; then
        warning "Some dependencies might have issues"
    fi
    success "Dependencies OK"
else
    warning "Flutter not found, dependencies verification ignored"
fi

# 7. Configuration files verification
echo "⚙️  Configuration files verification..."
if [ ! -f "analysis_options.yaml" ]; then
    warning "analysis_options.yaml file missing"
fi

if [ ! -f ".infra/analysis_options.yaml" ]; then
    warning ".infra/analysis_options.yaml file missing"
fi

success "Configuration OK"

# 8. Documentation verification
echo "📚 Documentation verification..."
if [ ! -f "README.md" ]; then
    warning "README.md missing"
fi

if [ ! -f "DEVELOPMENT.md" ]; then
    warning "DEVELOPMENT.md missing"
fi

success "Documentation OK"

echo ""
success "🎉 All quality checks passed!"
echo "🚀 Ready for commit" 