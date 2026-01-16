# Code Formatting Guide

This project uses `clang-format` to ensure consistent C++ code formatting.

## Quick Start

### Format All Files
```bash
./scripts/format_code.sh
```

### Format Specific Files
```bash
./scripts/format_code.sh path/to/file1.cpp path/to/file2.hpp
```

### Format Before Commit (Automatic)
The git pre-commit hook automatically formats staged C++ files before each commit.

## Manual Formatting

### Format a Single File
```bash
clang-format -i --style=file path/to/file.cpp
```

### Format All C++ Files in a Directory
```bash
find apps/onis_site_server/src -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i --style=file
```

## Pre-commit Hook

The pre-commit hook automatically:
1. Formats all staged C++ files
2. Re-stages the formatted files
3. Continues with other quality checks

### Install/Update Pre-commit Hook
```bash
cp .infra/pre-commit-hooks.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Skip Pre-commit Hook (if needed)
```bash
git commit --no-verify -m "message"
```

## Configuration

Formatting rules are defined in `.clang-format` in the project root.

## IDE Integration

### VS Code
Add to `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "C_Cpp.clang_format_style": "file",
  "[cpp]": {
    "editor.defaultFormatter": "ms-vscode.cpptools"
  }
}
```

### CLion
- Settings → Editor → Code Style → C/C++
- Set scheme to "Google" or import `.clang-format`
- Enable "Enable ClangFormat"

## Troubleshooting

### clang-format not found
```bash
# macOS
brew install clang-format

# Ubuntu/Debian
sudo apt-get install clang-format

# Verify installation
clang-format --version
```

### Formatting doesn't match .clang-format
Make sure you're using `--style=file` flag:
```bash
clang-format -i --style=file your_file.cpp
```

