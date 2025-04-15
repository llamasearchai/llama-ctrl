#!/bin/bash
# LlamaSearch Control Test Script
# ==============================
# This script tests if the installation is working properly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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

# Print banner
display_llama
echo -e "${BOLD}${MAGENTA}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║        LlamaSearch Control Test Utility              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for required commands
echo -e "${CYAN}Checking required dependencies:${NC}"

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "  • $1: ${GREEN}✓${NC}"
        return 0
    else
        echo -e "  • $1: ${RED}✗${NC} (Missing)"
        return 1
    fi
}

MISSING_DEPS=0

# Check system dependencies
check_command "python3" || ((MISSING_DEPS++))
check_command "pip3" || ((MISSING_DEPS++))
check_command "curl" || ((MISSING_DEPS++))
check_command "grep" || ((MISSING_DEPS++))
check_command "ollama" || ((MISSING_DEPS++))

# Check if Ollama is running
if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
    echo -e "  • Ollama Server: ${GREEN}Running${NC}"
    OLLAMA_RUNNING=true
else
    echo -e "  • Ollama Server: ${RED}Not running${NC}"
    OLLAMA_RUNNING=false
    ((MISSING_DEPS++))
fi

# Check for configuration
CONFIG_DIR="${HOME}/.config/llamasearch_ctrl"
CONFIG_FILE="${CONFIG_DIR}/.lsctrlrc"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "  • Config File: ${GREEN}Found${NC}"
else
    echo -e "  • Config File: ${RED}Missing${NC}"
    ((MISSING_DEPS++))
fi

# Check for Virtual Environment
VENV_DIR="${HOME}/.llamasearch_ctrl_src/venv"
if [ -d "$VENV_DIR" ]; then
    echo -e "  • Virtual Environment: ${GREEN}Found${NC}"
else
    echo -e "  • Virtual Environment: ${RED}Missing${NC}"
    ((MISSING_DEPS++))
fi

# Check for script files
if [ -f "run_lsctrl.sh" ] && [ -x "run_lsctrl.sh" ]; then
    echo -e "  • Launcher Script: ${GREEN}Found${NC}"
else
    echo -e "  • Launcher Script: ${RED}Missing or not executable${NC}"
    ((MISSING_DEPS++))
fi

if [ -f "ollama_setup.sh" ] && [ -x "ollama_setup.sh" ]; then
    echo -e "  • Setup Script: ${GREEN}Found${NC}"
else
    echo -e "  • Setup Script: ${RED}Missing or not executable${NC}"
    ((MISSING_DEPS++))
fi

# Check for Ollama models
if $OLLAMA_RUNNING; then
    echo -e "\n${CYAN}Checking available Ollama models:${NC}"
    MODELS=$(ollama list 2>/dev/null | grep -v "NAME" | awk '{print $1}' | tr '\n' ' ')
    
    if [ -n "$MODELS" ]; then
        echo -e "  • Models: ${GREEN}$MODELS${NC}"
    else
        echo -e "  • Models: ${RED}None found${NC}"
        ((MISSING_DEPS++))
    fi
fi

# Final assessment
echo -e "\n${CYAN}Installation Assessment:${NC}"

if [ $MISSING_DEPS -eq 0 ]; then
    echo -e "${GREEN}All components are installed and ready to use!${NC}"
    echo -e "You can use LlamaSearch Control by running: ${YELLOW}./run_lsctrl.sh${NC}"
    
    # Suggest a simple test
    echo -e "\n${CYAN}Would you like to run a simple test query? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Running test query: What is a Llama?${NC}"
        ./run_lsctrl.sh "What is a Llama? Give a very brief answer."
    fi
    
    exit 0
else
    echo -e "${RED}Some components are missing or not configured correctly.${NC}"
    echo -e "Please run the setup script: ${YELLOW}./ollama_setup.sh${NC}"
    exit 1
fi 