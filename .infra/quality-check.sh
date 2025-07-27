#!/bin/bash

# Quality check script for ONIS Viewer
# Manual code quality verifications

set -e

echo "🔍 Complete ONIS Viewer code quality verification..."
echo "=================================================="

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables for tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Function to display errors
error() {
    echo -e "${RED}❌ $1${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

# Function to display success
success() {
    echo -e "${GREEN}✅ $1${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

# Function to display warnings
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

# Function to display information
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to run a check
run_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    local check_name="$1"
    local command="$2"
    local success_msg="$3"
    local error_msg="$4"
    
    echo ""
    info "Check: $check_name"
    
    if eval "$command" > /dev/null 2>&1; then
        success "$success_msg"
    else
        error "$error_msg"
    fi
}

echo ""
echo "📱 DART/FLUTTER VERIFICATIONS"
echo "----------------------------"

# 1. Dart formatting
run_check \
    "Dart formatting" \
    "dart format --set-exit-if-changed lib/ test/" \
    "Dart code properly formatted" \
    "Dart code poorly formatted - run 'dart format .'"

# 2. Dart static analysis
run_check \
    "Dart static analysis" \
    "dart analyze" \
    "Dart static analysis OK" \
    "Issues detected by Dart static analysis"

# 3. Flutter tests
run_check \
    "Flutter tests" \
    "flutter test --no-pub" \
    "Flutter tests OK" \
    "Flutter tests failed"

# 4. Flutter compilation
run_check \
    "Flutter compilation" \
    "flutter build macos --debug" \
    "Flutter compilation OK" \
    "Flutter compilation failed"

echo ""
echo "⚙️  C++ VERIFICATIONS"
echo "-------------------"

# 5. C++ formatting
if command -v clang-format &> /dev/null; then
    CPP_FILES=$(find native/ -name "*.cpp" -o -name "*.h" 2>/dev/null || true)
    if [ -n "$CPP_FILES" ]; then
        run_check \
            "C++ formatting" \
            "clang-format --dry-run --Werror native/*.cpp native/*.h" \
            "C++ code properly formatted" \
            "C++ code poorly formatted - run 'clang-format -i native/*.cpp native/*.h'"
    else
        warning "No C++ files found"
    fi
else
    warning "clang-format not installed - verification ignored"
fi

# 6. C++ compilation (if possible)
if command -v cmake &> /dev/null && command -v make &> /dev/null; then
    run_check \
        "C++ compilation" \
        "cd macos && ./build_native.sh && cd .." \
        "C++ compilation OK" \
        "C++ compilation failed"
else
    warning "CMake or Make not installed - C++ compilation ignored"
fi

echo ""
echo "📦 DEPENDENCIES VERIFICATIONS"
echo "------------------------------"

# 7. Flutter dependencies
run_check \
    "Flutter dependencies" \
    "flutter pub deps --style=compact" \
    "Flutter dependencies OK" \
    "Issues with Flutter dependencies"

# 8. Outdated dependencies (warning only)
if flutter pub outdated --mode=null-safety 2>/dev/null | grep -q "Showing outdated packages"; then
    warning "Some dependencies have newer versions available"
    WARNINGS=$((WARNINGS + 1))
else
    success "All dependencies are up to date"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo ""
echo "📁 STRUCTURE VERIFICATIONS"
echo "----------------------------"

# 9. Configuration files
if [ -f "analysis_options.yaml" ]; then
    success "analysis_options.yaml file present"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    error "analysis_options.yaml file missing"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f ".infra/analysis_options.yaml" ]; then
    success ".infra/analysis_options.yaml file present"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    error ".infra/analysis_options.yaml file missing"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 10. Documentation
if [ -f "README.md" ]; then
    success "README.md present"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    error "README.md missing"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "DEVELOPMENT.md" ]; then
    success "DEVELOPMENT.md present"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    error "DEVELOPMENT.md missing"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo ""
echo "🔍 SECURITY VERIFICATIONS"
echo "---------------------------"

# 11. Secrets in code
if grep -r "password\|secret\|key\|token" lib/ --exclude-dir=generated 2>/dev/null | grep -v "//" | grep -v "TODO" > /dev/null; then
    warning "Possible secrets detected in code"
    WARNINGS=$((WARNINGS + 1))
else
    success "No secrets detected in code"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 12. Sensitive files
if [ -f ".env" ] || [ -f "secrets.json" ] || [ -f "config.json" ]; then
    warning "Sensitive files detected - verify they are not committed"
    WARNINGS=$((WARNINGS + 1))
else
    success "No sensitive files detected"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo ""
echo "📊 VERIFICATION SUMMARY"
echo "=========================="
echo "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed checks: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed checks: $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"

echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    success "🎉 All critical checks passed!"
    if [ $WARNINGS -gt 0 ]; then
        warning "⚠️  $WARNINGS warning(s) to review"
    fi
    exit 0
else
    error "❌ $FAILED_CHECKS critical check(s) failed"
    echo ""
    echo "🔧 Recommended actions:"
    echo "1. Fix detected errors"
    echo "2. Run 'dart format .' to format Dart code"
    echo "3. Run 'clang-format -i native/*.cpp native/*.h' to format C++ code"
    echo "4. Add missing documentation files"
    echo "5. Re-run this script to verify"
    exit 1
fi 