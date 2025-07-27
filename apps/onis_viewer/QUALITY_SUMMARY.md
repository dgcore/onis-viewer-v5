# Quality Infrastructure - ONIS Viewer

## 🎯 Overview

This document summarizes the complete quality infrastructure set up for the ONIS Viewer project. The goal is to ensure high and consistent code quality across the development team.

## 📁 Infrastructure Structure

```
onis_viewer/
├── .infra/                          # Quality infrastructure
│   ├── README.md                    # Infrastructure documentation
│   ├── analysis_options.yaml        # Dart/Flutter analysis rules
│   ├── .clang-format               # C++ formatting rules
│   ├── .editorconfig               # Editor configuration
│   ├── pre-commit-hooks.sh         # Git pre-commit hooks
│   ├── quality-check.sh            # Manual verification
│   └── setup-dev-environment.sh    # Automatic installation
├── .vscode/                         # VS Code configuration
│   ├── settings.json               # Editor settings
│   ├── extensions.json             # Recommended extensions
│   ├── tasks.json                  # Automated tasks
│   └── launch.json                 # Debug configurations
├── analysis_options.yaml           # Main analysis configuration
└── .gitignore                      # Versioning excluded files
```

## 🛠️ Quality Tools

### 1. Dart/Flutter Static Analysis
- **File**: `.infra/analysis_options.yaml`
- **Features**:
  - ✅ Naming convention verification (camelCase, PascalCase)
  - ✅ Dead code and unused code detection
  - ✅ Best practices verification
  - ✅ Documentation control
  - ✅ 80 character line limit
  - ✅ Mandatory explicit types

### 2. C++ Formatting
- **File**: `.infra/.clang-format`
- **Features**:
  - ✅ Google C++ style
  - ✅ Consistent indentation (2 spaces)
  - ✅ 80 character line limit
  - ✅ Automatic include sorting
  - ✅ Brace management

### 3. Editor Configuration
- **File**: `.infra/.editorconfig`
- **Features**:
  - ✅ Consistency between editors
  - ✅ Configuration by file type
  - ✅ Unix line endings management
  - ✅ UTF-8 encoding

### 4. Git Pre-commit Hooks
- **File**: `.infra/pre-commit-hooks.sh`
- **Automatic verifications**:
  - ✅ Dart/Flutter formatting
  - ✅ Dart static analysis
  - ✅ C++ formatting
  - ✅ Tests
  - ✅ Compilation
  - ✅ Dependencies
  - ✅ Documentation

### 5. Manual Verification
- **File**: `.infra/quality-check.sh`
- **Complete verifications**:
  - ✅ Dart/Flutter formatting and analysis
  - ✅ C++ formatting and compilation
  - ✅ Tests and compilation
  - ✅ Dependencies and security
  - ✅ Project structure

## 🚀 Usage

### Automatic Installation
```bash
# Complete environment configuration
./.infra/setup-dev-environment.sh
```

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
- ✅ No unused imports
- ✅ Appropriate error handling

### C++
- ✅ Variable names in `snake_case`
- ✅ Class names in `PascalCase`
- ✅ Constants in `UPPER_CASE`
- ✅ Lines limited to 80 characters
- ✅ Documentation with `///`
- ✅ Appropriate error handling
- ✅ No memory leaks
- ✅ Google C++ style

### General
- ✅ No trailing spaces
- ✅ Unix line endings (LF)
- ✅ UTF-8 encoding
- ✅ Up-to-date documentation
- ✅ Tests for new features
- ✅ No secrets in code

## 🔧 IDE Configuration

### VS Code
- **Automatic formatting** on save
- **Automatic problem fixing**
- **Automatically installed recommended extensions**
- **Automated tasks** for common operations
- **Ready-to-use debug configurations**

### IntelliJ/Android Studio
- **Automatic formatting** configured
- **Dart code style** applied
- **clang-format plugin** recommended

## 🚨 Automatic Verifications

### Pre-commit Hooks
Pre-commit hooks automatically verify before each commit:
1. Dart/Flutter formatting
2. Dart static analysis
3. C++ formatting
4. Tests
5. Compilation
6. Dependencies
7. Documentation

### CI/CD (Recommended)
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
3. Update the documentation
4. Document the changes

## 🎉 Result

This quality infrastructure ensures:
- ✅ **Consistency** of code across the team
- ✅ **Automatic detection** of issues
- ✅ **Automatic formatting** of code
- ✅ **Seamless integration** into the workflow
- ✅ **Complete documentation** and maintenance
- ✅ **Extensibility** for new rules

The team can now focus on developing advanced DICOM features while maintaining high code quality automatically. 