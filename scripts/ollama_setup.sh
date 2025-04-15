#!/bin/bash
# Ollama Setup and Optimization for M3 Max
# =======================================
# This script helps install and optimize Ollama for local LLM inference on M3 Max Macs

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
CONFIG_FILE="${CONFIG_DIR}/.lsctrlrc"
LOG_FILE="${CONFIG_DIR}/installation.log"
VENV_DIR="${HOME}/.llamasearch_ctrl_src/venv"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "$(date) - Starting LlamaSearch Control setup..."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}This script is designed for macOS only.${NC}"
    exit 1
fi

# Check if running on Apple Silicon
IS_APPLE_SILICON=false
if [[ "$(uname -m)" == "arm64" ]]; then
    IS_APPLE_SILICON=true
fi

# Check if running on M3 series
IS_M3_CHIP=false
if $IS_APPLE_SILICON; then
    CPU_INFO=$(sysctl -n machdep.cpu.brand_string)
    if [[ "$CPU_INFO" == *"M3"* ]]; then
        IS_M3_CHIP=true
    fi
fi

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
echo "║        LlamaSearch Control with Ollama Setup         ║"
echo "║       Optimized for Apple Silicon M3 Series          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Environment detection
echo -e "${CYAN}Environment Detection:${NC}"
echo -e "  • macOS: ${GREEN}✓${NC}"
if $IS_APPLE_SILICON; then
    echo -e "  • Apple Silicon: ${GREEN}✓${NC}"
    if $IS_M3_CHIP; then
        echo -e "  • M3 Series Chip: ${GREEN}✓${NC} (Optimizations will be applied)"
    else
        echo -e "  • M3 Series Chip: ${YELLOW}×${NC} (Apple Silicon optimizations still applied)"
    fi
else
    echo -e "${RED}This script is optimized for Apple Silicon Macs.${NC}"
    echo "While Ollama will work on Intel Macs, performance will be significantly limited."
    
    # Ask if user wants to continue anyway
    read -p "Do you want to continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 1
    fi
fi

# --- STEP 1: Install Prerequisites ---
echo -e "\n${BOLD}${CYAN}[1/5] Installing Prerequisites...${NC}"

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo -e "  • Homebrew: ${GREEN}✓${NC}"
fi

# Install Python 3.10+ if needed
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "Installing Python..."
    brew install python
else
    # Check Python version
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    if [[ "$PYTHON_VERSION" < "3.10" ]]; then
        echo -e "${YELLOW}Python version should be 3.10+. Current: $PYTHON_VERSION. Upgrading...${NC}"
        brew upgrade python
    else
        echo -e "  • Python $PYTHON_VERSION: ${GREEN}✓${NC}"
    fi
fi

# --- STEP 2: Install and Configure Ollama ---
echo -e "\n${BOLD}${CYAN}[2/5] Setting Up Ollama...${NC}"

# Check for Ollama
OLLAMA_INSTALLED=false
if command -v ollama >/dev/null 2>&1; then
    OLLAMA_INSTALLED=true
    OLLAMA_VERSION=$(ollama --version | awk '{print $2}')
    echo -e "  • Ollama: ${GREEN}✓${NC} (Version $OLLAMA_VERSION)"
fi

# Check if Ollama is running
OLLAMA_RUNNING=false
if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
    OLLAMA_RUNNING=true
    echo -e "  • Ollama Server: ${GREEN}Running${NC}"
else
    echo -e "  • Ollama Server: ${YELLOW}Not running${NC}"
fi

# Install or update Ollama
if ! $OLLAMA_INSTALLED; then
    echo -e "${CYAN}Installing Ollama...${NC}"
    brew install ollama
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Ollama with Homebrew.${NC}"
        echo "Trying direct installation method..."
        curl -fsSL https://ollama.com/install.sh | sh
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install Ollama. Please install manually from https://ollama.com${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Ollama installed successfully.${NC}"
else
    echo -e "${CYAN}Updating Ollama...${NC}"
    brew upgrade ollama
fi

# Create Ollama optimization file
OLLAMA_ENV_FILE="${HOME}/.ollama/ollama.env"
OLLAMA_CONF_DIR="${HOME}/.ollama"

mkdir -p "$OLLAMA_CONF_DIR"

echo -e "${CYAN}Creating optimized environment for Ollama...${NC}"

cat <<EOT > "$OLLAMA_ENV_FILE"
# Ollama optimizations for M3 Max
# Created by LlamaSearch Control setup script

# Use more GPU memory for better performance
OLLAMA_GPU_LAYERS=42

# Run on Metal for best performance
OLLAMA_USE_METAL=true
EOT

if $IS_M3_CHIP; then
    # Add M3-specific optimizations
    cat <<EOT >> "$OLLAMA_ENV_FILE"
# M3-specific optimizations
OLLAMA_NUM_THREADS=8
OLLAMA_METAL_MEMORY=6144
EOT
else
    # General Apple Silicon optimizations
    cat <<EOT >> "$OLLAMA_ENV_FILE"
# General Apple Silicon optimizations
OLLAMA_NUM_THREADS=4
OLLAMA_METAL_MEMORY=3072
EOT
fi

# Make sure permissions are correct
chmod 644 "$OLLAMA_ENV_FILE"

echo -e "${GREEN}Ollama environment configured for optimal performance on this Mac.${NC}"

# Start Ollama service if not running
if ! $OLLAMA_RUNNING; then
    echo -e "${CYAN}Starting Ollama service...${NC}"
    # Stop any existing service first
    pkill -f ollama >/dev/null 2>&1 || true
    
    # Start as a background process
    ollama serve &
    
    # Wait for it to start
    echo -n "Waiting for Ollama server to start"
    for i in {1..10}; do
        if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
            OLLAMA_RUNNING=true
            break
        fi
        echo -n "."
        sleep 1
    done
    echo
    
    if $OLLAMA_RUNNING; then
        echo -e "${GREEN}Ollama server started successfully.${NC}"
    else
        echo -e "${YELLOW}Ollama server did not start automatically. Please start it manually:${NC}"
        echo "ollama serve"
    fi
fi

# --- STEP 3: Setup LlamaSearch Control ---
echo -e "\n${BOLD}${CYAN}[3/5] Setting Up LlamaSearch Control...${NC}"

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${CYAN}Creating Python virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}Virtual environment created at $VENV_DIR${NC}"
fi

# Activate virtual environment
echo -e "${CYAN}Activating virtual environment...${NC}"
source "$VENV_DIR/bin/activate"

# Install LlamaSearch Control dependencies
echo -e "${CYAN}Installing Python dependencies...${NC}"
pip install --upgrade pip
pip install typer rich distro instructor pyreadline3 litellm openai

# Update LlamaSearch Control config to use Ollama
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${CYAN}Updating LlamaSearch Control config to use Ollama...${NC}"
    
    # Check if essential settings already exist
    USE_LITELLM_SET=$(grep -c "USE_LITELLM=true" "$CONFIG_FILE" || echo "0")
    API_BASE_SET=$(grep -c "API_BASE_URL=http://localhost:11434" "$CONFIG_FILE" || echo "0")
    MODEL_SET=$(grep -c "DEFAULT_MODEL=ollama/" "$CONFIG_FILE" || echo "0")
    
    # Backup the config file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Update settings
    if [[ "$USE_LITELLM_SET" == "0" ]]; then
        echo "USE_LITELLM=true" >> "$CONFIG_FILE"
    else
        sed -i '' 's/USE_LITELLM=false/USE_LITELLM=true/g' "$CONFIG_FILE"
    fi
    
    if [[ "$API_BASE_SET" == "0" ]]; then
        echo "API_BASE_URL=http://localhost:11434" >> "$CONFIG_FILE"
    else
        sed -i '' 's|API_BASE_URL=.*|API_BASE_URL=http://localhost:11434|g' "$CONFIG_FILE"
    fi
    
    # Only set model if not already set to an ollama model
    if [[ "$MODEL_SET" == "0" ]]; then
        echo "DEFAULT_MODEL=ollama/llama3" >> "$CONFIG_FILE"
    fi
    
    # Set a dummy API key for LiteLLM
    if ! grep -q "OPENAI_API_KEY=ollama" "$CONFIG_FILE"; then
        echo "OPENAI_API_KEY=ollama_key" >> "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}LlamaSearch Control config updated for Ollama.${NC}"
else
    echo -e "${CYAN}Creating LlamaSearch Control config file...${NC}"
    mkdir -p "$CONFIG_DIR"
    
    cat <<EOT > "$CONFIG_FILE"
# LlamaSearch Control Configuration
# Created by Ollama setup script

# API Settings
USE_LITELLM=true
API_BASE_URL=http://localhost:11434
DEFAULT_MODEL=ollama/llama3
OPENAI_API_KEY=ollama_key

# UI Settings
DEFAULT_COLOR=magenta
CODE_THEME=dracula
PRETTIFY_MARKDOWN=true
SHELL_INTERACTION=true

# Cache Settings
CHAT_CACHE_LENGTH=100
CACHE_LENGTH=100

# Apple Silicon Optimizations
USE_METAL_ACCELERATION=true
OPTIMIZE_MEMORY=true
EOT
    
    echo -e "${GREEN}LlamaSearch Control config created.${NC}"
fi

# --- STEP 4: Download Models ---
echo -e "\n${BOLD}${CYAN}[4/5] Downloading Models...${NC}"

# Pull recommended models
echo -e "${CYAN}Would you like to download recommended models? (This may take some time)${NC}"
echo -e "1. ${YELLOW}Llama 3 8B${NC} (recommended, ~5GB)"
echo -e "2. ${BLUE}Mistral 7B${NC} (~5GB)"
echo -e "3. ${GREEN}Phi-3 mini${NC} (smaller, ~2GB)"
echo -e "4. ${MAGENTA}Download all recommended models${NC}"
echo -e "5. ${RED}Skip model download${NC} (do this manually later)"

read -p "Enter your choice (1-5): " model_choice

case $model_choice in
    1)
        echo -e "${CYAN}Downloading Llama 3 8B...${NC}"
        ollama pull llama3
        ;;
    2)
        echo -e "${CYAN}Downloading Mistral 7B...${NC}"
        ollama pull mistral
        ;;
    3)
        echo -e "${CYAN}Downloading Phi-3 mini...${NC}"
        ollama pull phi3:mini
        ;;
    4)
        echo -e "${CYAN}Downloading all recommended models...${NC}"
        echo "This will require ~12GB of disk space and may take some time."
        read -p "Are you sure? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Downloading Llama 3 8B...${NC}"
            ollama pull llama3
            echo -e "${CYAN}Downloading Mistral 7B...${NC}"
            ollama pull mistral
            echo -e "${CYAN}Downloading Phi-3 mini...${NC}"
            ollama pull phi3:mini
        fi
        ;;
    5)
        echo -e "${YELLOW}Skipping model download.${NC}"
        echo "You can download models later with: ollama pull <model_name>"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Skipping model download.${NC}"
        ;;
esac

# Show available models
echo -e "${CYAN}Available Ollama models:${NC}"
ollama list

# --- STEP 5: Test Installation ---
echo -e "\n${BOLD}${CYAN}[5/5] Testing Installation...${NC}"

# Define the llamasearch-ctrl script path in the virtual environment
LSCTRL_SCRIPT_PATH="${VENV_DIR}/bin/lsctrl"

# Create a basic lsctrl script if it doesn't exist yet
if [ ! -f "$LSCTRL_SCRIPT_PATH" ]; then
    echo -e "${CYAN}Creating LlamaSearch Control script...${NC}"
    
    mkdir -p "${VENV_DIR}/bin"
    
    cat <<EOT > "$LSCTRL_SCRIPT_PATH"
#!/usr/bin/env python3
# LlamaSearch Control CLI entry point

import os
import sys
import subprocess

def main():
    # Configure environment variables
    os.environ["USE_LITELLM"] = "true"
    os.environ["API_BASE_URL"] = "http://localhost:11434"
    os.environ["DEFAULT_MODEL"] = "ollama/llama3"
    
    # If using OpenAI API, it would be configured here
    # os.environ["OPENAI_API_KEY"] = "your_api_key"
    
    # Parse arguments
    args = sys.argv[1:]
    
    # Prepare the command
    cmd = ["litellm", "--model", "ollama/llama3"]
    
    # Add arguments
    if args:
        cmd.extend(args)
    
    try:
        # Run the command
        result = subprocess.run(cmd, text=True, capture_output=True)
        print(result.stdout.strip())
        if result.stderr:
            print(f"Error: {result.stderr.strip()}", file=sys.stderr)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOT
    
    chmod +x "$LSCTRL_SCRIPT_PATH"
    echo -e "${GREEN}LlamaSearch Control script created.${NC}"
fi

# Install the main package
echo -e "${CYAN}Installing LlamaSearch Control...${NC}"
pip install git+https://github.com/TheR1D/shell_gpt.git || {
    echo -e "${RED}Failed to install from git, falling back to pip...${NC}"
    pip install shell-gpt
}

# Create run_lsctrl.sh script
echo -e "${CYAN}Creating launcher script...${NC}"

LAUNCHER_SCRIPT="${SCRIPT_DIR}/run_lsctrl.sh"

cat <<EOT > "$LAUNCHER_SCRIPT"
#!/bin/bash
# LlamaSearch Control - Launcher for macOS 
# =======================================
# This script provides a convenient way to run LlamaSearch Control,
# automatically detecting your environment and applying optimizations.

# Get the script's directory
SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"

# Default installation location
DEFAULT_INSTALL_DIR="${HOME}/.llamasearch_ctrl_src"
VENV_DIR="${VENV_DIR}"
LSCTRL_CMD="\${VENV_DIR}/bin/lsctrl"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "\$(uname)" != "Darwin" ]]; then
    echo -e "\${RED}This script is optimized for macOS.\${NC}"
    echo "You can still run LlamaSearch Control directly using the 'lsctrl' command."
    exit 1
fi

# Check if running on Apple Silicon
IS_APPLE_SILICON=false
if [[ "\$(uname -m)" == "arm64" ]]; then
    IS_APPLE_SILICON=true
fi

# Check if running on M3 series chip
IS_M3_CHIP=false
if \$IS_APPLE_SILICON; then
    CPU_INFO=\$(sysctl -n machdep.cpu.brand_string)
    if [[ "\$CPU_INFO" == *"M3"* ]]; then
        IS_M3_CHIP=true
    fi
fi

# Check if Ollama is installed and running
OLLAMA_RUNNING=false
if command -v ollama >/dev/null 2>&1; then
    if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
        OLLAMA_RUNNING=true
    fi
fi

# Function to display the llama art
display_llama() {
    echo -e "\${MAGENTA}"
    echo '                 ^    ^                 '
    echo '               /  \__/  \               '
    echo '              /  (oo)  \               '
    echo '             /    \/    \               '
    echo '            /            \              '
    echo '           |   ⨊⨊⨊⨊⨊⨊⨊⨊⨊  |              '
    echo '            \  ⨊⨊⨊⨊⨊⨊⨊⨊ /               '
    echo '             \  ⨊⨊⨊⨊⨊⨊ /                '
    echo '              \________/                 '
    echo -e "\${NC}"
}

# Print banner
display_llama
echo -e "\${BOLD}\${MAGENTA}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║               LlamaSearch Control                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "\${NC}"

# Environment detection
echo -e "\${CYAN}Environment Detection:\${NC}"
echo -e "  • macOS: \${GREEN}✓\${NC}"
if \$IS_APPLE_SILICON; then
    echo -e "  • Apple Silicon: \${GREEN}✓\${NC}"
    if \$IS_M3_CHIP; then
        echo -e "  • M3 Series Chip: \${GREEN}✓\${NC} (Applying optimizations)"
    else
        echo -e "  • M3 Series Chip: \${YELLOW}×\${NC} (Apple Silicon optimizations still applied)"
    fi
else
    echo -e "  • Apple Silicon: \${YELLOW}×\${NC} (Running on Intel)"
fi

if \$OLLAMA_RUNNING; then
    echo -e "  • Ollama Server: \${GREEN}Running\${NC}"
else
    echo -e "  • Ollama Server: \${YELLOW}Not detected\${NC} (Consider running 'ollama serve')"
fi

# Check for LlamaSearch Control installation
if [[ ! -x "\$LSCTRL_CMD" ]]; then
    echo -e "\${RED}Error: LlamaSearch Control not found at \${LSCTRL_CMD}\${NC}"
    echo "Please run the installation script first: ollama_setup.sh"
    exit 1
fi

# Apply optimizations based on hardware
if \$IS_M3_CHIP; then
    echo -e "\${CYAN}Applying M3-specific optimizations...\${NC}"
    # Set Metal optimizations for TensorFlow
    export TF_METAL_DEVICE_PREALLOCATED_MEMORY=2000
    export TF_FORCE_GPU_ALLOW_GROWTH=true
    
    # Performance core utilization
    export OMP_NUM_THREADS=8
    export MKL_NUM_THREADS=8
    
    # Neural Engine (if applicable)
    export ENABLE_NEURAL_ENGINE=1
    
    # Memory optimization
    export LLAMASEARCH_MEMORY_OPTIMIZE=true
elif \$IS_APPLE_SILICON; then
    echo -e "\${CYAN}Applying Apple Silicon optimizations...\${NC}"
    # Standard Apple Silicon optimizations
    export TF_METAL_DEVICE_PREALLOCATED_MEMORY=1000
    export TF_FORCE_GPU_ALLOW_GROWTH=true
    export OMP_NUM_THREADS=4
    export MKL_NUM_THREADS=4
fi

# Activate virtual environment
if [[ -f "\${VENV_DIR}/bin/activate" ]]; then
    source "\${VENV_DIR}/bin/activate"
    
    echo -e "\${GREEN}Virtual environment activated\${NC}"
    echo -e "\${BOLD}Running: \${BLUE}lsctrl \$@\${NC}"
    
    # Run the command with all arguments passed through
    lsctrl "\$@"
    
    # Store exit code
    EXIT_CODE=\$?
    
    # Deactivate virtual environment
    deactivate
    
    # Exit with the same code as the command
    exit \$EXIT_CODE
else
    # Try to run directly if activation fails
    echo -e "\${YELLOW}Warning: Could not activate virtual environment.\${NC}"
    echo -e "\${BOLD}Running: \${BLUE}\${LSCTRL_CMD} \$@\${NC}"
    
    "\$LSCTRL_CMD" "\$@"
    exit \$?
fi
EOT

chmod +x "$LAUNCHER_SCRIPT"
echo -e "${GREEN}Launcher script created at $LAUNCHER_SCRIPT${NC}"

# Run a test query if a model is available
if ollama list | grep -q "llama\|mistral\|phi"; then
    echo -e "${CYAN}Testing LlamaSearch Control with a simple query...${NC}"
    
    # Deactivate and reactivate virtual environment to ensure clean state
    deactivate 2>/dev/null || true
    source "$VENV_DIR/bin/activate"
    
    # Run test query
    echo -e "${YELLOW}Test Query: What is a Llama?${NC}"
    "${LAUNCHER_SCRIPT}" "What is a Llama? Give a very short answer."
    
    echo -e "\n${GREEN}Test complete! If you see a response above, your installation is working.${NC}"
else
    echo -e "${YELLOW}No models available for testing. Please download a model first using 'ollama pull llama3' and then test manually.${NC}"
fi

# Final instructions
display_llama
echo -e "\n${BOLD}${GREEN}Installation Complete!${NC}"
echo -e "${CYAN}You can now use LlamaSearch Control with local Ollama models:${NC}"
echo -e "  1. Run the launcher script: ${BOLD}${YELLOW}./run_lsctrl.sh \"Your question here\"${NC}"
echo -e "  2. Or directly use: ${BOLD}${YELLOW}source ${VENV_DIR}/bin/activate && lsctrl \"Your question here\"${NC}"

echo -e "\n${CYAN}Example commands:${NC}"
echo -e "  • ${YELLOW}./run_lsctrl.sh \"Explain quantum computing\"${NC}"
echo -e "  • ${YELLOW}./run_lsctrl.sh -s \"find all PDFs larger than 10MB\"${NC} (shell command generation)"
echo -e "  • ${YELLOW}./run_lsctrl.sh -c \"write a Python function to download a file\"${NC} (code generation)"
echo -e "  • ${YELLOW}./run_lsctrl.sh --chat project \"How do I structure a React project?\"${NC} (chat mode)"

if [ "$model_choice" == "5" ]; then
    echo -e "\n${YELLOW}Don't forget to download at least one model:${NC}"
    echo "  ollama pull llama3    # Recommended default model"
    echo "  ollama pull mistral   # Alternative model"
    echo "  ollama pull phi3:mini # Smaller, faster model"
fi

echo -e "\n${CYAN}To change the default model, edit ${CONFIG_FILE}${NC}"
echo "and update the DEFAULT_MODEL setting."

# Display full installation summary if it exists
if [ -f "${SCRIPT_DIR}/installation_summary.txt" ]; then
    echo -e "\n${CYAN}Press Enter to view the full installation summary...${NC}"
    read
    clear
    cat "${SCRIPT_DIR}/installation_summary.txt"
else
    echo -e "\n${BOLD}${GREEN}Enjoy using LlamaSearch Control with local Ollama models!${NC}"
fi

# Deactivate virtual environment
deactivate 2>/dev/null || true

# End of script
echo "$(date) - LlamaSearch Control setup completed successfully." >> "$LOG_FILE"
