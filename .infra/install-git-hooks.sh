#!/bin/bash

# Git hooks installation script for ONIS Viewer
# Automatically installs pre-commit hooks

set -e

echo "🔧 Installing Git hooks for ONIS Viewer..."

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

# Check if we're in a Git repository
if [ ! -d ".git" ]; then
    error "Not in a Git repository. Please run this script from the project root."
fi

# Create hooks directory if it doesn't exist
if [ ! -d ".git/hooks" ]; then
    mkdir -p .git/hooks
    info "Created .git/hooks directory"
fi

# Install pre-commit hook
info "Installing pre-commit hook..."
if [ -f ".infra/pre-commit-hooks.sh" ]; then
    cp .infra/pre-commit-hooks.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    success "Pre-commit hook installed"
else
    error "Pre-commit hook script not found at .infra/pre-commit-hooks.sh"
fi

# Create a simple commit-msg hook for commit message formatting
info "Installing commit-msg hook..."
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash

# Commit message format validation
# Ensures commit messages follow conventional format

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Check if commit message follows conventional format
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .+"; then
    echo "❌ Invalid commit message format."
    echo "Please use conventional commit format:"
    echo "  <type>(<scope>): <description>"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
    echo "Example: feat(dicom): add image loading functionality"
    echo ""
    exit 1
fi

echo "✅ Commit message format is valid"
EOF

chmod +x .git/hooks/commit-msg
success "Commit-msg hook installed"

# Create a prepare-commit-msg hook to add issue references
info "Installing prepare-commit-msg hook..."
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash

# Prepare commit message hook
# Adds issue references and other metadata

commit_msg_file="$1"
commit_type="$2"
commit_hash="$3"

# If this is a merge commit, don't modify the message
if [ "$commit_type" = "merge" ]; then
    exit 0
fi

# Get current branch name
branch_name=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# Add branch name as prefix if it's a feature branch
if [[ "$branch_name" =~ ^(feature|bugfix|hotfix|release)/.* ]]; then
    # Extract issue number from branch name (e.g., feature/123-add-dicom -> #123)
    issue_number=$(echo "$branch_name" | grep -o '[0-9]\+' | head -1)
    if [ -n "$issue_number" ]; then
        # Add issue reference to commit message
        sed -i.bak "1s/^/Closes #$issue_number\n/" "$commit_msg_file"
        rm -f "$commit_msg_file.bak"
    fi
fi
EOF

chmod +x .git/hooks/prepare-commit-msg
success "Prepare-commit-msg hook installed"

# Create a post-commit hook for notifications
info "Installing post-commit hook..."
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash

# Post-commit hook
# Provides feedback after successful commit

echo ""
echo "🎉 Commit successful!"
echo "📝 Next steps:"
echo "  - Push your changes: git push"
echo "  - Create a pull request if needed"
echo "  - Run tests: flutter test"
echo "  - Check quality: ./.infra/quality-check.sh"
echo ""
EOF

chmod +x .git/hooks/post-commit
success "Post-commit hook installed"

# Create a pre-push hook for additional checks
info "Installing pre-push hook..."
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

# Pre-push hook
# Additional checks before pushing to remote

echo "🔍 Running pre-push checks..."



# Run tests
if command -v flutter &> /dev/null; then
    if ! flutter test --no-pub > /dev/null 2>&1; then
        echo "❌ Tests failed3. Please fix tests before pushing."
        exit 1
    fi
    echo "✅ Tests passed"
fi

echo "🚀 Ready to push!"
EOF

chmod +x .git/hooks/pre-push
success "Pre-push hook installed"

echo ""
success "🎉 All Git hooks installed successfully!"
echo ""
echo "📋 Installed hooks:"
echo "  - pre-commit: Code quality checks"
echo "  - commit-msg: Commit message format validation"
echo "  - prepare-commit-msg: Issue reference addition"
echo "  - post-commit: Success feedback"
echo "  - pre-push: Additional quality and test checks"
echo ""
echo "🔧 Hook behavior:"
echo "  - Pre-commit: Automatically formats code and runs tests"
echo "  - Commit-msg: Ensures conventional commit format"
echo "  - Pre-push: Runs full quality check and tests"
echo ""
echo "💡 Tips:"
echo "  - Use conventional commit format: feat(dicom): add image loading"
echo "  - Branch names with issue numbers will auto-link: feature/123-add-dicom"
echo "  - Hooks can be bypassed with --no-verify flag (not recommended)" 