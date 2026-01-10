#!/bin/bash
#
# deploy-page.sh - Set up Cloudflare Pages for a wbtl.app tool
#
# Usage: ./deploy-page.sh --dist <folder> [--build <command>]
#
# This script:
#   1. Verifies you're in a valid wbtl-app tool directory
#   2. Checks if a Cloudflare Pages project already exists
#   3. Creates a new Cloudflare Pages project connected to GitHub
#   4. Sets up DNS entry for <tool>.wbtl.app
#
# Required environment variables (set in scripts/.env):
#   - CLOUDFLARE_ACCOUNT_ID
#   - CLOUDFLARE_API_TOKEN
#   - CLOUDFLARE_ZONE_ID (for wbtl.app domain)

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

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

# Parse arguments
DIST_FOLDER=""
BUILD_CMD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dist|-d)
            DIST_FOLDER="$2"
            shift 2
            ;;
        --build|-b)
            BUILD_CMD="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --dist <folder> [--build <command>]"
            echo ""
            echo "Options:"
            echo "  --dist, -d   Distribution folder (required)"
            echo "  --build, -b  Build command (optional)"
            echo ""
            echo "Example:"
            echo "  $0 --dist dist --build 'npm run build'"
            echo "  $0 --dist public"
            exit 0
            ;;
        *)
            error "Unknown option: $1\nRun '$0 --help' for usage."
            ;;
    esac
done

# Validate dist folder is provided
if [ -z "$DIST_FOLDER" ]; then
    error "Distribution folder is required.\n\nUsage: $0 --dist <folder> [--build <command>]\n\nExample: $0 --dist dist --build 'npm run build'"
fi

# Check for required environment variables
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    error "CLOUDFLARE_ACCOUNT_ID is not set.\nAdd it to $SCRIPT_DIR/.env or set as environment variable."
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    error "CLOUDFLARE_API_TOKEN is not set.\nAdd it to $SCRIPT_DIR/.env or set as environment variable."
fi

if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    error "CLOUDFLARE_ZONE_ID is not set (for wbtl.app domain).\nAdd it to $SCRIPT_DIR/.env or set as environment variable."
fi

# Verify we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    error "Not a git repository.\nRun this script from the root of a wbtl-app tool repository."
fi

# Get the remote origin URL
ORIGIN_URL=$(git remote get-url origin 2>/dev/null) || error "No git remote 'origin' found."

# Verify it's a wbtl-app repo
if [[ ! "$ORIGIN_URL" =~ github\.com[:/]wbtl-app/ ]]; then
    error "This doesn't appear to be a wbtl-app repository.\nOrigin: $ORIGIN_URL\nExpected: github.com/wbtl-app/<tool-name>"
fi

# Extract tool name from origin URL
if [[ "$ORIGIN_URL" =~ github\.com[:/]wbtl-app/([^/]+?)(\.git)?$ ]]; then
    TOOL_NAME="${BASH_REMATCH[1]}"
else
    error "Could not extract tool name from origin URL: $ORIGIN_URL"
fi

# Remove .git suffix if present
TOOL_NAME="${TOOL_NAME%.git}"

info "Detected tool: $TOOL_NAME"

# Generate 4 random hex characters
random_suffix() {
    head -c 2 /dev/urandom | xxd -p
}

# Check if error indicates name is taken
is_name_taken_error() {
    local response="$1"
    local error_code=$(echo "$response" | grep -o '"code": *[0-9]*' | head -1 | grep -o '[0-9]*')
    local error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1)

    [[ "$error_code" == "8000014" ]] || echo "$error_msg" | grep -qi "already.*taken\|name.*exists\|duplicate"
}

# Create build config JSON
if [ -n "$BUILD_CMD" ]; then
    BUILD_CONFIG='{
        "build_command": "'"$BUILD_CMD"'",
        "destination_dir": "'"$DIST_FOLDER"'",
        "root_dir": ""
    }'
else
    BUILD_CONFIG='{
        "build_command": "",
        "destination_dir": "'"$DIST_FOLDER"'",
        "root_dir": ""
    }'
fi

# Check if project already exists in our account (error if so - no retry for this)
BASE_PROJECT_NAME="wbtl-app-$TOOL_NAME"
PROJECT_NAME="$BASE_PROJECT_NAME"

info "Checking if project exists in your account: $PROJECT_NAME"
EXISTING_PROJECT=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/$PROJECT_NAME" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")

if echo "$EXISTING_PROJECT" | grep -q '"success": *true'; then
    error "Cloudflare Pages project '$PROJECT_NAME' already exists in your account!"
fi

# Try to create project (with retries only for GLOBAL name conflicts)
MAX_ATTEMPTS=10
ATTEMPT=1
PROJECT_CREATED=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$PROJECT_CREATED" = "false" ]; do
    info "Creating Cloudflare Pages project '$PROJECT_NAME'..."
    CREATE_RESPONSE=$(curl -s -X POST \
        "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{
            "name": "'"$PROJECT_NAME"'",
            "production_branch": "main",
            "source": {
                "type": "github",
                "config": {
                    "owner": "wbtl-app",
                    "repo_name": "'"$TOOL_NAME"'",
                    "production_branch": "main",
                    "pr_comments_enabled": true,
                    "deployments_enabled": true,
                    "production_deployments_enabled": true,
                    "preview_deployment_setting": "all",
                    "preview_branch_includes": ["*"],
                    "preview_branch_excludes": []
                }
            },
            "build_config": '"$BUILD_CONFIG"'
        }')

    if echo "$CREATE_RESPONSE" | grep -q '"success": *true'; then
        PROJECT_CREATED=true
    elif is_name_taken_error "$CREATE_RESPONSE"; then
        # Name is taken GLOBALLY by someone else - retry with random suffix
        if [ $ATTEMPT -eq 1 ]; then
            warn "Project name '$PROJECT_NAME' is taken globally by another user."
            warn "Trying with random suffix..."
        else
            warn "Name '$PROJECT_NAME' also taken. Retrying... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        fi
        PROJECT_NAME="$BASE_PROJECT_NAME-$(random_suffix)"
        ATTEMPT=$((ATTEMPT + 1))
    else
        # Some other error occurred
        ERROR_MSG=$(echo "$CREATE_RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"$//')
        error "Failed to create Cloudflare Pages project.\nError: $ERROR_MSG\n\nFull response: $CREATE_RESPONSE"
    fi
done

if [ "$PROJECT_CREATED" = "false" ]; then
    error "Failed to create project after $MAX_ATTEMPTS attempts. All names were taken globally."
fi

if [ "$PROJECT_NAME" != "$BASE_PROJECT_NAME" ]; then
    success "Cloudflare Pages project created as '$PROJECT_NAME'"
    info "Note: Using alternate name because '$BASE_PROJECT_NAME' was taken globally"
else
    success "Cloudflare Pages project created"
fi

# Get the pages.dev subdomain
PAGES_SUBDOMAIN=$(echo "$CREATE_RESPONSE" | grep -o '"subdomain":"[^"]*"' | sed 's/"subdomain":"//;s/"$//')
info "Pages subdomain: $PAGES_SUBDOMAIN.pages.dev"

# Set up DNS CNAME record for <tool>.wbtl.app
CUSTOM_DOMAIN="$TOOL_NAME.wbtl.app"
info "Setting up DNS for $CUSTOM_DOMAIN..."

# Check if DNS record already exists
EXISTING_DNS=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$CUSTOM_DOMAIN&type=CNAME" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")

DNS_COUNT=$(echo "$EXISTING_DNS" | grep -o '"count": *[0-9]*' | grep -o '[0-9]*')

if [ "$DNS_COUNT" != "0" ] && [ -n "$DNS_COUNT" ]; then
    warn "DNS record for $CUSTOM_DOMAIN already exists. Skipping DNS setup."
else
    # Create CNAME record pointing to pages.dev
    DNS_RESPONSE=$(curl -s -X POST \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{
            "type": "CNAME",
            "name": "'"$TOOL_NAME"'",
            "content": "'"$PROJECT_NAME"'.pages.dev",
            "proxied": true,
            "ttl": 1
        }')

    if ! echo "$DNS_RESPONSE" | grep -q '"success": *true'; then
        ERROR_MSG=$(echo "$DNS_RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"$//')
        warn "Failed to create DNS record: $ERROR_MSG"
        warn "You may need to add the CNAME manually in Cloudflare DNS."
    else
        success "DNS CNAME record created"
    fi
fi

# Add custom domain to Pages project
info "Adding custom domain to Pages project..."
DOMAIN_RESPONSE=$(curl -s -X POST \
    "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/$PROJECT_NAME/domains" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{
        "name": "'"$CUSTOM_DOMAIN"'"
    }')

if ! echo "$DOMAIN_RESPONSE" | grep -q '"success": *true'; then
    ERROR_MSG=$(echo "$DOMAIN_RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"$//')
    warn "Failed to add custom domain: $ERROR_MSG"
    warn "You may need to add the custom domain manually in Cloudflare Pages settings."
else
    success "Custom domain added to Pages project"
fi

echo ""
success "Cloudflare Pages deployment setup complete!"
echo ""
echo "Project: https://dash.cloudflare.com/?to=/:account/pages/view/$PROJECT_NAME"
echo "Pages URL: https://$PROJECT_NAME.pages.dev"
echo "Custom domain: https://$CUSTOM_DOMAIN"
echo ""
echo "Build configuration:"
echo "  Distribution folder: $DIST_FOLDER"
if [ -n "$BUILD_CMD" ]; then
    echo "  Build command: $BUILD_CMD"
else
    echo "  Build command: (none)"
fi
echo ""
echo "Next steps:"
echo "  1. Push code to the main branch to trigger a deployment"
echo "  2. Wait for DNS propagation (usually a few minutes)"
echo "  3. Visit https://$CUSTOM_DOMAIN to see your tool"
