#!/bin/bash

# Format all C++ files in the project using clang-format
# Usage: ./scripts/format_code.sh [file1] [file2] ...

set -e

# Colors for messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display success
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to display warnings
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if clang-format is available
if ! command -v clang-format &> /dev/null; then
    warning "clang-format not found. Please install it:"
    echo "  macOS: brew install clang-format"
    echo "  Ubuntu: sudo apt-get install clang-format"
    exit 1
fi

# Find .clang-format file
CLANG_FORMAT_FILE=".clang-format"
if [ ! -f "$CLANG_FORMAT_FILE" ]; then
    warning ".clang-format file not found in root directory"
    exit 1
fi

# If files are provided as arguments, format only those
if [ $# -gt 0 ]; then
    FILES="$@"
else
    # Find all C++ files in the project
    FILES=$(find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.cc" -o -name "*.cxx" \) \
        ! -path "./build/*" \
        ! -path "./.git/*" \
        ! -path "*/Pods/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/build/*" \
        ! -path "*/_deps/*")
fi

FORMATTED_COUNT=0
TOTAL_COUNT=0

for file in $FILES; do
    if [ -f "$file" ]; then
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        echo "Formatting: $file"
        clang-format -i --style=file "$file"
        FORMATTED_COUNT=$((FORMATTED_COUNT + 1))
    fi
done

if [ $TOTAL_COUNT -eq 0 ]; then
    warning "No C++ files found to format"
else
    success "Formatted $FORMATTED_COUNT file(s)"
fi

