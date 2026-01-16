#!/bin/bash

# Format only staged C++ files before commit
# This script is called by the git pre-commit hook

set -e

# Check if clang-format is available
if ! command -v clang-format &> /dev/null; then
    exit 0  # Silently skip if clang-format is not available
fi

# Find .clang-format file
CLANG_FORMAT_FILE=".clang-format"
if [ ! -f "$CLANG_FORMAT_FILE" ]; then
    exit 0  # Silently skip if .clang-format is not found
fi

# Get staged C++ files
CPP_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cpp|h|hpp|cc|cxx)$' || true)

if [ -z "$CPP_FILES" ]; then
    exit 0  # No C++ files to format
fi

# Format each staged file
for file in $CPP_FILES; do
    if [ -f "$file" ]; then
        clang-format -i --style=file "$file"
        # Re-stage the formatted file
        git add "$file"
    fi
done

exit 0

