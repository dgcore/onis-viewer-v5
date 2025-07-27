# Quality Infrastructure - ONIS Viewer

This `.infra` folder contains all the tools and configurations to ensure code quality in the ONIS Viewer project.

## 📁 Structure

```
.infra/
├── README.md                    # This file
├── analysis_options.yaml        # Dart/Flutter analysis configuration
├── .clang-format               # C++ formatting configuration
├── .editorconfig               # EditorConfig configuration
├── pre-commit-hooks.sh         # Pre-commit hooks script
└── quality-check.sh            # Manual verification script
```

## 🛠️ Quality Tools

### 1. Dart/Flutter Static Analysis
- **File**: `analysis_options.yaml`
- **Usage**: Automatic via `dart analyze`
- **Features**:
  - Naming convention verification (camelCase, PascalCase)
  - Dead code and unused code detection
  - Best practices verification
  - Documentation control

### 2. C++ Formatting
- **File**: `.clang-format`
- **Usage**: `clang-format -i file.cpp`
- **Features**:
  - Consistent indentation (2 spaces)
  - 80 character line limit
  - Google C++ style
  - Automatic include sorting

### 3. Editor Configuration
- **File**: `.editorconfig`
- **Usage**: Automatic in supported editors
- **Features**:
  - Consistency between editors
  - Configuration by file type
  - Line ending management

## 🚀 Usage

### Manual Verification
```bash
# Complete quality verification
./.infra/quality-check.sh

# Quick verification (pre-commit hooks)
./.infra/pre-commit-hooks.sh
```

### Automatic Formatting
```bash
# Dart/Flutter formatting
dart format .

# C++ formatting
clang-format -i native/*.cpp native/*.h

# Formatting with specific configuration
clang-format -i --style=file native/*.cpp
```

### Git Integration
```bash
# Install pre-commit hooks
cp .infra/pre-commit-hooks.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 📋 Quality Rules

### Dart/Flutter
- ✅ Variable names in `camelCase`
- ✅ Class names in `PascalCase`
- ✅ Constants in `UPPER_CASE`
- ✅ Lines limited to 80 characters
- ✅ Mandatory documentation for public APIs
- ✅ Explicit types for parameters
- ✅ Use of `const` and `final` when possible

### C++
- ✅ Variable names in `snake_case`
- ✅ Class names in `PascalCase`
- ✅ Constants in `UPPER_CASE`
- ✅ Lines limited to 80 characters
- ✅ Documentation with `///`
- ✅ Appropriate error handling
- ✅ No memory leaks

### General
- ✅ No trailing spaces
- ✅ Unix line endings (LF)
- ✅ UTF-8 encoding
- ✅ Up-to-date documentation
- ✅ Tests for new features

## 🔧 IDE Configuration

### VS Code
Add to `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.formatOnSave": true,
  "dart.analyzerPath": "dart",
  "clang-format.executable": "clang-format",
  "clang-format.style": "file"
}
```

### IntelliJ/Android Studio
- Enable "Format on Save"
- Configure Dart code style
- Install clang-format plugin

## 🚨 Automatic Verifications

### Pre-commit Hooks
Pre-commit hooks automatically verify:
1. Dart/Flutter formatting
2. Dart static analysis
3. C++ formatting
4. Tests
5. Compilation
6. Dependencies
7. Documentation

### CI/CD (Recommended)
Add to your CI pipeline:
```yaml
- name: Quality Check
  run: ./.infra/quality-check.sh
```

## 📊 Quality Metrics

### Objectives
- **Test coverage**: > 80%
- **Cyclomatic complexity**: < 10
- **Lines per function**: < 50
- **Files per module**: < 20
- **API documentation**: 100%

### Recommended Tools
- **SonarQube**: Complete quality analysis
- **Codecov**: Test coverage
- **Dependabot**: Dependency updates
- **GitHub Actions**: Automated CI/CD

## 🔍 Troubleshooting

### Common Errors

#### "dart format" fails
```bash
# Check syntax
dart analyze

# Format manually
dart format lib/ test/
```

#### "clang-format" not found
```bash
# Install clang-format
# macOS
brew install clang-format

# Ubuntu
sudo apt-get install clang-format

# Windows
# Download from LLVM
```

#### Pre-commit hooks fail
```bash
# Check permissions
chmod +x .git/hooks/pre-commit

# Test manually
./.infra/pre-commit-hooks.sh
```

## 📚 Resources

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Lints](https://dart.dev/go/flutter-lints)
- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [EditorConfig](https://editorconfig.org/)
- [Pre-commit Hooks](https://pre-commit.com/)

## 🤝 Contribution

To add new quality rules:
1. Modify the appropriate configuration files
2. Test with `./.infra/quality-check.sh`
3. Update this README
4. Document the changes

---

**Note**: These tools are designed to improve code quality without slowing down development. Adjust the rules according to your team's needs. 