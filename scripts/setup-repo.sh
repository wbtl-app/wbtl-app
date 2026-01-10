#!/bin/bash
#
# setup-repo.sh - Create a new tool repository in the wbtl-app organization
#
# Usage: ./setup-repo.sh <tool-name>
#
# This script:
#   1. Validates the tool name (letters, numbers, dashes only)
#   2. Checks if the repo already exists on GitHub
#   3. Creates a new repo in the wbtl-app organization
#   4. Sets up a local folder at ~/projects/wbtl-app/<tool-name>
#   5. Initializes with a README and pushes initial commit
#   6. Copies template files locally (NOT committed):
#      - template/tool.html
#      - docs/icon-guidelines.md
#      - If matching spec exists: experiment/tool-specs/<tool-name>.md and .svg

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WBTL_REPO_DIR="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="$HOME/projects/wbtl-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check for required tools
command -v gh >/dev/null 2>&1 || error "GitHub CLI (gh) is required. Install: https://cli.github.com/"

# Validate arguments
if [ -z "$1" ]; then
    error "Usage: $0 <tool-name>\n\nExample: $0 timer"
fi

TOOL_NAME="$1"

# Validate tool name (letters, numbers, dashes only, must start with letter)
if [[ ! "$TOOL_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    error "Invalid tool name: '$TOOL_NAME'\nMust contain only lowercase letters, numbers, and dashes.\nMust start with a letter.\nExamples: timer, json-format, pdf-merge"
fi

# Check for double dashes
if [[ "$TOOL_NAME" =~ -- ]]; then
    error "Invalid tool name: '$TOOL_NAME'\nCannot contain consecutive dashes."
fi

# Check if ends with dash
if [[ "$TOOL_NAME" =~ -$ ]]; then
    error "Invalid tool name: '$TOOL_NAME'\nCannot end with a dash."
fi

info "Validating tool name: $TOOL_NAME"

# Check if repo already exists on GitHub
info "Checking if repo already exists on GitHub..."
if gh repo view "wbtl-app/$TOOL_NAME" >/dev/null 2>&1; then
    error "Repository 'wbtl-app/$TOOL_NAME' already exists on GitHub!"
fi

success "Repo name is available"

# Check if local folder already exists
LOCAL_DIR="$PROJECTS_DIR/$TOOL_NAME"
if [ -d "$LOCAL_DIR" ]; then
    error "Local folder already exists: $LOCAL_DIR"
fi

# Create the repo on GitHub
info "Creating repository 'wbtl-app/$TOOL_NAME' on GitHub..."
gh repo create "wbtl-app/$TOOL_NAME" \
    --public \
    --description "wbtl.app tool: $TOOL_NAME" \
    || error "Failed to create GitHub repository"

success "GitHub repository created"

# Create local folder
info "Creating local folder: $LOCAL_DIR"
mkdir -p "$LOCAL_DIR"

# Initialize git repo
info "Initializing local git repository..."
cd "$LOCAL_DIR"
git init -b main

# Set up origin
info "Setting up remote origin..."
git remote add origin "https://github.com/wbtl-app/$TOOL_NAME.git"

# Create initial README
info "Creating initial README..."
cat > README.md << EOF
# $TOOL_NAME

A wbtl.app tool.

Visit: https://$TOOL_NAME.wbtl.app
EOF

# Create initial commit and push
info "Creating initial commit..."
git add README.md
git commit -m "Initial commit"

info "Pushing to GitHub..."
git push -u origin main

success "Repository initialized and pushed to GitHub"

# Copy template files (NOT to be committed)
info "Copying template files..."

# Copy tool.html template
if [ -f "$WBTL_REPO_DIR/template/tool.html" ]; then
    cp "$WBTL_REPO_DIR/template/tool.html" "$LOCAL_DIR/tool.html"
    success "Copied: tool.html"
else
    warn "Template not found: $WBTL_REPO_DIR/template/tool.html"
fi

# Check for matching spec files (exact match required)
SPEC_MD="$WBTL_REPO_DIR/experiment/tool-specs/$TOOL_NAME.md"
SPEC_SVG="$WBTL_REPO_DIR/experiment/tool-specs/$TOOL_NAME.svg"

if [ -f "$SPEC_MD" ] && [ -f "$SPEC_SVG" ]; then
    cp "$SPEC_MD" "$LOCAL_DIR/$TOOL_NAME.md"
    cp "$SPEC_SVG" "$LOCAL_DIR/$TOOL_NAME.svg"
    success "Copied spec files: $TOOL_NAME.md and $TOOL_NAME.svg"
elif [ -f "$SPEC_MD" ]; then
    warn "Found $TOOL_NAME.md but missing $TOOL_NAME.svg - not copying either"
elif [ -f "$SPEC_SVG" ]; then
    warn "Found $TOOL_NAME.svg but missing $TOOL_NAME.md - not copying either"
else
    info "No matching spec files found for '$TOOL_NAME' in experiment/tool-specs/"
fi

echo ""
success "Tool repository setup complete!"
echo ""
echo "Repository: https://github.com/wbtl-app/$TOOL_NAME"
echo "Local path: $LOCAL_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $LOCAL_DIR"
echo "  2. Review copied template files (NOT committed)"
echo "  3. Start building your tool"
echo "  4. Run deploy-page.sh to set up Cloudflare hosting"
