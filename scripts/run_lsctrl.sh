#!/bin/bash
# LlamaSearch Control - Launcher for macOS 
# =======================================
# This script provides a convenient way to run LlamaSearch Control,
# automatically detecting your environment and applying optimizations.

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default installation location
DEFAULT_INSTALL_DIR="${HOME}/.llamasearch_ctrl_src"
VENV_DIR="${DEFAULT_INSTALL_DIR}/venv"
LSCTRL_CMD="${VENV_DIR}/bin/lsctrl"

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
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}This script is optimized for macOS.${NC}"
    echo "You can still run LlamaSearch Control directly using the 'lsctrl' command."
    exit 1
fi

# Check if running on Apple Silicon
IS_APPLE_SILICON=false
if [[ "$(uname -m)" == "arm64" ]]; then
    IS_APPLE_SILICON=true
fi

# Check if running on M3 series chip
IS_M3_CHIP=false
if $IS_APPLE_SILICON; then
    CPU_INFO=$(sysctl -n machdep.cpu.brand_string)
    if [[ "$CPU_INFO" == *"M3"* ]]; then
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

# Print banner
echo -e "${BOLD}${MAGENTA}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║               LlamaSearch Control                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Environment detection
echo -e "${CYAN}Environment Detection:${NC}"
echo -e "  • macOS: ${GREEN}✓${NC}"
if $IS_APPLE_SILICON; then
    echo -e "  • Apple Silicon: ${GREEN}✓${NC}"
    if $IS_M3_CHIP; then
        echo -e "  • M3 Series Chip: ${GREEN}✓${NC} (Applying optimizations)"
    else
        echo -e "  • M3 Series Chip: ${YELLOW}×${NC} (Apple Silicon optimizations still applied)"
    fi
else
    echo -e "  • Apple Silicon: ${YELLOW}×${NC} (Running on Intel)"
fi

if $OLLAMA_RUNNING; then
    echo -e "  • Ollama Server: ${GREEN}Running${NC}"
else
    echo -e "  • Ollama Server: ${YELLOW}Not detected${NC} (Consider installing for local LLM inference)"
fi

# Check for LlamaSearch Control installation
if [[ ! -x "$LSCTRL_CMD" ]]; then
    echo -e "${RED}Error: LlamaSearch Control not found at ${LSCTRL_CMD}${NC}"
    echo "Please run the installation script first: install_llamasearch_ctrl.sh"
    exit 1
fi

# Apply optimizations based on hardware
if $IS_M3_CHIP; then
    echo -e "${CYAN}Applying M3-specific optimizations...${NC}"
    # Set Metal optimizations for TensorFlow
    export TF_METAL_DEVICE_PREALLOCATED_MEMORY=2000
    export TF_FORCE_GPU_ALLOW_GROWTH=true
    
    # Performance core utilization
    export OMP_NUM_THREADS=6
    export MKL_NUM_THREADS=6
    
    # Neural Engine (if applicable)
    export ENABLE_NEURAL_ENGINE=1
    
    # Memory optimization
    export LLAMASEARCH_MEMORY_OPTIMIZE=true
elif $IS_APPLE_SILICON; then
    echo -e "${CYAN}Applying Apple Silicon optimizations...${NC}"
    # Standard Apple Silicon optimizations
    export TF_METAL_DEVICE_PREALLOCATED_MEMORY=1000
    export TF_FORCE_GPU_ALLOW_GROWTH=true
    export OMP_NUM_THREADS=4
fi

# Activate virtual environment or add to PATH
if [[ -f "${VENV_DIR}/bin/activate" ]]; then
    source "${VENV_DIR}/bin/activate"
    
    echo -e "${GREEN}Virtual environment activated${NC}"
    echo -e "${BOLD}Running: ${BLUE}lsctrl $@${NC}"
    
    # Run the command with all arguments passed through
    lsctrl "$@"
    
    # Store exit code
    EXIT_CODE=$?
    
    # Deactivate virtual environment
    deactivate
    
    # Exit with the same code as the command
    exit $EXIT_CODE
else
    # Try to run directly if activation fails
    echo -e "${YELLOW}Warning: Could not activate virtual environment.${NC}"
    echo -e "${BOLD}Running: ${BLUE}${LSCTRL_CMD} $@${NC}"
    
    "$LSCTRL_CMD" "$@"
    exit $?
fi
