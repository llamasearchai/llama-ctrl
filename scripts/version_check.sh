#!/bin/bash
# LlamaSearch Control Version Check Script
# =======================================
# This script checks for updates to LlamaSearch Control and notifies the user

VERSION="1.6.0"
REPO_URL="https://raw.githubusercontent.com/your-repo/main"
VERSION_CHECK_URL="${REPO_URL}/version.txt"
CHANGELOG_URL="${REPO_URL}/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Config paths
CONFIG_DIR="${HOME}/.config/llamasearch_ctrl"

# Function to display the llama art
display_llama() {
    echo -e "${MAGENTA}"
    echo '                 ^    ^                 '
    echo '               /  \__/  \               '
    echo '              /  (oo)  \               '
    echo '             /    \/    \               '
    echo '            /            \              '
    echo '           |   ⨊⨊⨊⨊⨊⨊⨊⨊⨊  |              '
    echo '            \  ⨊⨊⨊⨊⨊⨊⨊⨊ /               '
    echo '             \  ⨊⨊⨊⨊⨊⨊ /                '
    echo '              \________/                 '
    echo -e "${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for updates only once a day
VERSION_CHECK_FILE="${CONFIG_DIR}/.version_check"
CURRENT_DATE=$(date +%Y-%m-%d)
LAST_CHECK_DATE=""

if [ -f "$VERSION_CHECK_FILE" ]; then
    LAST_CHECK_DATE=$(cat "$VERSION_CHECK_FILE")
fi

# Only check for updates if we haven't checked today
if [ "$LAST_CHECK_DATE" != "$CURRENT_DATE" ]; then
    # Create the config dir if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Update the last check date
    echo "$CURRENT_DATE" > "$VERSION_CHECK_FILE"
    
    # Check for Internet connectivity first
    if command_exists curl; then
        if ! curl -s --head --max-time 2 "$VERSION_CHECK_URL" >/dev/null; then
            # No internet or couldn't reach the server, skip version check
            exit 0
        fi
        
        # Get the latest version
        LATEST_VERSION=$(curl -s --max-time 5 "$VERSION_CHECK_URL" 2>/dev/null)
        
        # Compare versions if we got a valid response
        if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$VERSION" ]; then
            display_llama
            echo -e "${BOLD}${CYAN}LlamaSearch Control Update Available!${NC}"
            echo -e "Current version: ${YELLOW}v${VERSION}${NC}"
            echo -e "Latest version:  ${GREEN}v${LATEST_VERSION}${NC}"
            echo
            echo -e "To update, run: ${BOLD}bash ollama_setup.sh${NC}"
            echo
            echo -e "For release notes, visit:"
            echo -e "${BLUE}${CHANGELOG_URL}${NC}"
            echo
        fi
    fi
fi

# Exit silently if no update is available or we can't check
exit 0 