#!/usr/bin/env bash
# LlamaSearch Control - Enhanced Installation Script (v1.6.0) for Apple Silicon
# ================================================================
# This script contains the complete source code for LlamaSearch Control
# Optimized for M3 Max macOS environment

set -e # Exit immediately if a command exits with a non-zero status.

# --- Script Configuration ---
PROJECT_NAME="LlamaSearch Control"
PACKAGE_NAME="llamasearch_ctrl"
COMMAND_NAME="lsctrl"
VERSION="1.6.0" # Enhanced version for Apple Silicon
INSTALL_DIR="${HOME}/.${PACKAGE_NAME}_src"
CONFIG_DIR="${HOME}/.config/${PACKAGE_NAME}"
CONFIG_FILE="${CONFIG_DIR}/.${COMMAND_NAME}rc"
VENV_DIR="${INSTALL_DIR}/venv"
REQUIRED_PYTHON_MAJOR=3
REQUIRED_PYTHON_MINOR=10

# --- Helper Functions ---
print_info() {
    printf "[INFO] %s\n" "$1"
}

print_success() {
    # Use green color if terminal supports it
    if [[ -t 1 ]]; then
        printf "\e[32m[SUCCESS]\e[0m %s\n" "$1"
    else
        printf "[SUCCESS] %s\n" "$1"
    fi
}

print_warning() {
    # Use yellow color if terminal supports it
    if [[ -t 1 ]]; then
        printf "\e[33m[WARNING]\e[0m %s\n" "$1" >&2
    else
        printf "[WARNING] %s\n" "$1" >&2
    fi
}

print_error() {
    # Use red color if terminal supports it
    if [[ -t 1 ]]; then
        printf "\e[31m[ERROR]\e[0m %s\n" "$1" >&2
    else
        printf "[ERROR] %s\n" "$1" >&2
    fi
    exit 1
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "'$1' is required but not found. Please install it (e.g., using Homebrew: 'brew install $2', or your system's package manager)."
    fi
}

check_python_version() {
    print_info "Checking Python version..."
    check_command python3 python
    PYTHON_VERSION=$(python3 --version 2>&1)
    if [[ "$PYTHON_VERSION" =~ Python\ ([0-9]+)\.([0-9]+) ]]; then
        local MAJOR=${BASH_REMATCH[1]}
        local MINOR=${BASH_REMATCH[2]}
        if [[ $MAJOR -lt $REQUIRED_PYTHON_MAJOR ]] || ([[ $MAJOR -eq $REQUIRED_PYTHON_MAJOR ]] && [[ $MINOR -lt $REQUIRED_PYTHON_MINOR ]]); then
            print_error "Python version ${REQUIRED_PYTHON_MAJOR}.${REQUIRED_PYTHON_MINOR} or higher is required. Found ${MAJOR}.${MINOR}. Please install or update Python (e.g., 'brew install python' or use your system's package manager)."
        else
            print_success "Python version ${MAJOR}.${MINOR} found."
        fi
    else
        print_warning "Could not accurately parse Python version string: '$PYTHON_VERSION'. Proceeding, but Python ${REQUIRED_PYTHON_MAJOR}.${REQUIRED_PYTHON_MINOR}+ is required."
    fi
    check_command pip3 python # pip usually comes with python
}

# Function to check if running on Apple Silicon
check_apple_silicon() {
    print_info "Checking system architecture..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        print_success "Apple Silicon (M-series) detected: $ARCH"
        return 0
    else
        print_warning "Not running on Apple Silicon. Found architecture: $ARCH"
        print_warning "This script is optimized for Apple Silicon Macs. It may still work, but some optimizations won't apply."
        return 1
    fi
}

# --- Main Execution ---
print_info "Starting installation of ${PROJECT_NAME} (${COMMAND_NAME}) v${VERSION}..."

# 1. Prerequisites Check
print_info "Checking prerequisites..."
check_python_version
IS_APPLE_SILICON=false
check_apple_silicon && IS_APPLE_SILICON=true

# 2. Setup Project Directory
print_info "Setting up project directory at ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}" || print_error "Could not create installation directory ${INSTALL_DIR}"
cd "${INSTALL_DIR}" || print_error "Could not change to installation directory ${INSTALL_DIR}"
print_success "Project directory ready."

# 3. Embed and Write Source Files
print_info "Creating source files..."

# --- pyproject.toml ---
mkdir -p "${INSTALL_DIR}"
cat <<'EOF' > "${INSTALL_DIR}/pyproject.toml"
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "llamasearch_ctrl"
description = "A command-line productivity tool powered by large language models (like Llama, GPT-4, etc.), helping you accomplish tasks faster."
keywords = ["shell", "llama", "gpt", "openai", "ollama", "cli", "productivity", "cheatsheet", "search", "control"]
readme = "README.md"
license = "MIT"
requires-python = ">=3.10"
authors = [{ name = "LlamaSearch Control Team (Based on ShellGPT by Farkhod Sadykov)", email = "farkhod@sadykov.dev" }]
dynamic = ["version"]
classifiers = [
    "Operating System :: OS Independent",
    "Operating System :: MacOS",
    "Operating System :: POSIX :: Linux",
    "Topic :: Software Development",
    "Topic :: System :: Shells",
    "Topic :: Utilities",
    "License :: OSI Approved :: MIT License",
    "Intended Audience :: Information Technology",
    "Intended Audience :: System Administrators",
    "Intended Audience :: Developers",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3.13",
]
dependencies = [
    "openai >= 1.34.0, < 2.0.0",
    "typer[all] >= 0.7.0, < 1.0.0", # Use [all] for rich completions
    "click >= 7.1.1, < 9.0.0",
    "rich >= 13.1.0, < 14.0.0",
    "distro >= 1.8.0, < 2.0.0",
    "instructor >= 1.0.0, < 2.0.0",
    'pyreadline3 >= 3.4.1, < 4.0.0; sys_platform == "win32"', # Keep for potential cross-platform use
]

[project.optional-dependencies]
# Include litellm directly as it's often desired with "Llama" branding
litellm = [
    "litellm >= 1.42.5" # Use >= for potential updates, check compatibility if issues arise
]
test = [
    "pytest >= 7.2.2, < 9.0.0", # Loosen upper bound slightly
    "requests-mock[fixture] >= 1.10.0, < 2.0.0",
    "isort >= 5.12.0, < 6.0.0",
    "black >= 23.1.0, < 25.0.0", # Allow newer black versions
    "mypy >= 1.1.1, < 2.0.0", # Allow newer mypy
    "types-requests >= 2.28.11.17",
    "codespell >= 2.2.5, < 3.0.0",
    "pytest-cov >= 4.0.0" # Added for coverage reporting
]
dev = [
    "ruff >= 0.1.0, < 1.0.0", # Update ruff range
    "pre-commit >= 3.1.1, < 4.0.0",
]
# Add a new optimized group for Apple Silicon Macs
apple_silicon = [
    "tensorflow-macos >= 2.12.0",
    "tensorflow-metal >= 1.0.0",
    "numpy >= 1.24.0"
]

[project.scripts]
lsctrl = "llamasearch_ctrl.app:entry_point" # Corrected entry point format

[project.urls]
homepage = "https://github.com/TheR1D/shell_gpt" # Update if you fork
repository = "https://github.com/TheR1D/shell_gpt" # Update if you fork
documentation = "https://github.com/TheR1D/shell_gpt/blob/main/README.md" # Update if you fork

[tool.hatch.version]
path = "llamasearch_ctrl/__version__.py" # Adjusted path

[tool.hatch.build.targets.wheel]
packages = ["llamasearch_ctrl"] # Use packages instead of only-include for standard builds

[tool.hatch.build.targets.sdist]
include = [ # Use include for broader coverage
    "/llamasearch_ctrl",
    "/tests",
    "/scripts",
    "/README.md",
    "/LICENSE",
    "/CONTRIBUTING.md",
    "/pyproject.toml",
    "/Dockerfile",
    "/.devcontainer",
    "/.github",
]

[tool.isort]
profile = "black"
skip_gitignore = true # Useful in projects

[tool.mypy]
strict = true
exclude = ["llamasearch_ctrl/llm_functions", "venv", ".venv", "build", "dist"] # Adjusted path, exclude venv/build dirs
ignore_missing_imports = true # Be a bit more lenient for potentially missing stubs

[tool.ruff]
line-length = 88 # Explicitly match black
target-version = "py310" # Minimum Python version

[tool.ruff.lint]
select = [
    "E", # pycodestyle errors
    "W", # pycodestyle warnings
    "F", # pyflakes
    "C4", # flake8-comprehensions C4 instead of C
    "B", # flake8-bugbear
    "I", # isort
    "UP", # pyupgrade
    "S", # flake8-bandit (Security checks)
    "A", # flake8-builtins
    "T20", # flake8-print (discourage print in library code)
]
ignore = [
    "E501", # line too long, handled by black
    "C901", # too complex (consider refactoring if this appears often)
    "B008", # do not perform function calls in argument defaults
    "E731", # do not assign a lambda expression, use a def
    "S101", # assert usage (okay in tests)
    "T201", # Allow `print` in specific places like utils/scripts
]

# Ignore T201 specifically in app.py, utils.py where print is used for user output
[tool.ruff.lint.per-file-ignores]
"llamasearch_ctrl/app.py" = ["T201"]
"llamasearch_ctrl/utils.py" = ["T201"]
"llamasearch_ctrl/config.py" = ["T201"]
"llamasearch_ctrl/role.py" = ["T201"]
"llamasearch_ctrl/function.py" = ["T201"]
"llamasearch_ctrl/llm_functions/*" = ["T201"]
"llamasearch_ctrl/handlers/handler.py" = ["T201"]
"llamasearch_ctrl/handlers/chat_handler.py" = ["T201"]
"llamasearch_ctrl/handlers/repl_handler.py" = ["T201"]
"install_*.sh" = ["T201"] # Allow print in install script if linted
"scripts/*.py" = ["T201"]
"tests/*" = ["S101", "T201"] # Allow assert and print in tests

[tool.ruff.format]
quote-style = "double"
indent-style = "space"

[tool.codespell]
skip = '*.pyc,*.log,*.json,*.lock,venv,.venv,.git,.mypy_cache,build,dist,*egg-info*,coverage.xml' # Added more common ignores
ignore-words-list = "instal,bundler,hist,nd,te,fpr" # Add common false positives or project specific terms
EOF

# --- Create README.md ---
mkdir -p "${INSTALL_DIR}"
cat <<'EOF' > "${INSTALL_DIR}/README.md"
# LlamaSearch Control (lsctrl)

**LlamaSearch Control** (`lsctrl`) is a command-line productivity tool powered by AI large language models (LLMs) like Llama 2/3, GPT-4, Claude, Mistral, and others. This tool offers streamlined generation of **shell commands, code snippets, documentation, and answers to your queries**, directly in your terminal, reducing the need for external resources like web searches. 

It supports Linux, macOS (including Apple Silicon optimizations), Windows and is compatible with major shells like PowerShell, CMD, Bash, Zsh, etc.

*This project is a rebranded and enhanced fork of the excellent [ShellGPT by TheR1D](https://github.com/TheR1D/shell_gpt).*

## Installation

You can install `llamasearch-ctrl` using the self-contained script:

```shell
# Using the installation script (Recommended for initial setup)
bash ./install_llamasearch_ctrl.sh
```

By default, LlamaSearch Control can use OpenAI's API. If you choose this, you'll need an API key from [OpenAI](https://platform.openai.com/api-keys). The script will prompt you for your key during the first run if it's not set via the `OPENAI_API_KEY` environment variable. The key will be stored securely in `~/.config/llamasearch-ctrl/.lsctrlrc`.

> **🚀 Using Local Models (Llama, Mistral, etc.)**
> 
> You can easily configure `lsctrl` to use locally hosted open-source models via backends like **[Ollama](https://github.com/ollama/ollama)**, LM Studio, vLLM, etc. This is often **free** and **private**.
> 
> **Setup with Ollama:**
> 1. Install and run [Ollama](https://ollama.com/).
> 2. Pull a model: `ollama pull llama3` or `ollama pull mistral`.
> 3. Edit your `~/.config/llamasearch-ctrl/.lsctrlrc` file and set:
> ```ini
> # Use LiteLLM to proxy requests
> USE_LITELLM=true
> # Point to your Ollama server (default)
> API_BASE_URL=http://localhost:11434
> # Specify the Ollama model (prefix with 'ollama/')
> DEFAULT_MODEL=ollama/llama3
> # You can put any string here for LiteLLM when using local models
> OPENAI_API_KEY=ollama_key
> ```
> 4. Run `lsctrl`! Example: `lsctrl "Explain quantum entanglement simply"`

## Usage

`lsctrl` is designed for quick analysis and information retrieval.

```shell
# Ask a general question
lsctrl "What is the difference between a virtual environment and a container?"
# -> A virtual environment isolates Python packages for a project, while a container...

# Pipe input for analysis or transformation
git diff | lsctrl "Generate a concise git commit message for these changes"
# -> refactor: Improve error handling in data processing module

# Analyze logs for errors
docker logs my-app | lsctrl "Find errors in these logs and suggest fixes"
# -> Error found: NullPointerException at line 152. Suggestion: Check if 'userData' is null before accessing methods...

# Use stdin redirection
lsctrl "Summarize this document" < report.txt
# -> The document outlines the quarterly financial performance...

# Use heredocs for multi-line input
lsctrl << EOF
What's the best way to learn Rust in 2025?
Provide a simple 'Hello, world!' example.
EOF
# -> The best way involves the official Rust book, practice projects...
# -> ```rust
# -> fn main() {
# -> println!("Hello, world!");
# -> }
# -> ```
```

### Shell Command Generation (`--shell`, `-s`)

Forget a command? Need a complex one-liner? Use `-s`:

```shell
lsctrl -s "find all '.log' files modified in the last 2 days and zip them"
# -> find . -name "*.log" -type f -mtime -2 -print0 | zip logs.zip -@
# -> Action? [E(xecute)/D(escribe)/A(bort)]: e
```

`lsctrl` is OS-aware and suggests appropriate commands:

```shell
# On macOS:
lsctrl -s "update all my installed software"
# -> brew update && brew upgrade
# -> Action? [E(xecute)/D(escribe)/A(bort)]: e

# On Ubuntu/Debian:
lsctrl -s "update all my installed software"
# -> sudo apt update && sudo apt upgrade -y
# -> Action? [E(xecute)/D(escribe)/A(bort)]: e
```

### Shell Integration (Ctrl+L - Zsh/Bash)

Get suggestions directly in your terminal prompt with the shell integration!

1. Run `lsctrl --install-integration`.
2. Restart your shell (or source `~/.bashrc`/`~/.zshrc`).
3. Type part of a command or a description, then press `Ctrl+L`.
4. `lsctrl` replaces your input buffer with the suggested command.
5. Edit if needed, then press Enter.

### Code Generation (`--code`, `-c`)

Get clean code snippets:

```shell
lsctrl -c "python function to calculate factorial recursively"
# -> def factorial(n):
# -> if n == 0:
# -> return 1
# -> else:
# -> return n * factorial(n-1)

# Redirect to a file
lsctrl -c "Simple Flask app with a single route" > app.py
python app.py
```

Pipe existing code for modifications:

```shell
cat utils.py | lsctrl -c "Add type hints to this Python code"
```

### Chat Mode (`--chat`)

Maintain conversation context. Use a session name (`--chat <name>`) or `temp` for a disposable session.

```shell
lsctrl --chat project_setup "What are the steps to initialize a Python project with poetry?"
# -> 1. Install poetry... 2. Run `poetry init`...

lsctrl --chat project_setup "Now add 'requests' as a dependency"
# -> Okay, run `poetry add requests`
```

### REPL Mode (`--repl`)

Interactive chat loop. Great for exploration and iterative tasks.

```shell
lsctrl --repl temp
# Entering REPL mode (LlamaSearch Control). Press Ctrl+C or type 'exit()' to quit.
# >>> Explain the 'async' and 'await' keywords in Python
# -> `async` and `await` are used for asynchronous programming...
# >>> Give a simple example using asyncio
# -> import asyncio ... (code example)
```

### Configuration File (`~/.config/llamasearch-ctrl/.lsctrlrc`)

This file allows customization of `lsctrl`'s behavior. Create it if it doesn't exist.

Key options include:
* `OPENAI_API_KEY`: Your API key (or placeholder).
* `API_BASE_URL`: Endpoint for your LLM API (OpenAI, Ollama, etc.).
* `USE_LITELLM`: Set to `true` to use LiteLLM (for local models).
* `DEFAULT_MODEL`: The default LLM model name.

## Apple Silicon Optimizations

This version includes specific optimizations for Apple Silicon (M1/M2/M3) Macs:
- Utilizes Metal acceleration for TensorFlow operations
- Configures memory allocation for optimal performance on Apple chips
- Enhanced CPU/GPU coordination for LLM inference

## License

MIT License - see `LICENSE`.
Based on ShellGPT, also MIT licensed.
EOF

# --- Create LICENSE ---
mkdir -p "${INSTALL_DIR}"
cat <<'EOF' > "${INSTALL_DIR}/LICENSE"
MIT License

Copyright (c) 2023 Farkhod Sadykov
Copyright (c) 2024 LlamaSearch Control Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# --- Create Source Files ---
mkdir -p "${INSTALL_DIR}/${PACKAGE_NAME}"

# --- Create __version__.py ---
cat <<EOF > "${INSTALL_DIR}/${PACKAGE_NAME}/__version__.py"
# Specifies the version of the LlamaSearch Control package.
# Used by pyproject.toml (via hatch) and can be imported in the app.
__version__ = "${VERSION}"
EOF

# --- Create __init__.py ---
cat <<'EOF' > "${INSTALL_DIR}/${PACKAGE_NAME}/__init__.py"
# LlamaSearch Control Package Initializer
from .app import entry_point as entry_point  # noqa: F401
from .app import main as main  # Keep main import if used directly elsewhere
from .__version__ import __version__  # Make version accessible

__all__ = ["entry_point", "main", "__version__"]
EOF

# --- Create __main__.py ---
cat <<'EOF' > "${INSTALL_DIR}/${PACKAGE_NAME}/__main__.py"
# Allows running the package directly using `python -m llamasearch_ctrl`
import sys
from .app import entry_point

if __name__ == "__main__":
    # If run as `python -m llamasearch_ctrl` with no args, Typer's no_args_is_help=True
    # should handle showing the help message via the entry_point call.
    entry_point()
EOF

# --- Add Apple Silicon optimizations ---
mkdir -p "${INSTALL_DIR}/${PACKAGE_NAME}/apple"
cat <<'EOF' > "${INSTALL_DIR}/${PACKAGE_NAME}/apple/__init__.py"
# Apple Silicon Optimizations for LlamaSearch Control
import platform
import os
import sys

def is_apple_silicon():
    """Check if running on Apple Silicon (M1/M2/M3)."""
    return platform.system() == "Darwin" and platform.machine() == "arm64"

def optimize_for_apple_silicon():
    """Apply optimizations for Apple Silicon if running on M1/M2/M3."""
    if not is_apple_silicon():
        return False
        
    try:
        # Configure TensorFlow for Metal acceleration
        os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
        os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"  # Reduce TF logging
        
        # Try to configure Metal for accelerated ML operations
        try:
            import tensorflow as tf
            tf.config.experimental.set_visible_devices([], 'GPU')
            tf.config.threading.set_inter_op_parallelism_threads(1)
            tf.config.threading.set_intra_op_parallelism_threads(2)
        except ImportError:
            # TensorFlow not available, skip this optimization
            pass
        
        # Optimize numpy if available (used by many LLM libraries)
        try:
            import numpy as np
            np.set_printoptions(precision=8, suppress=True)
        except ImportError:
            pass
            
        return True
    except Exception as e:
        print(f"[INFO] Apple Silicon optimization attempt failed: {e}", file=sys.stderr)
        return False
EOF

# --- Create config.py with Apple Silicon optimization ---
cat <<'EOF' > "${INSTALL_DIR}/${PACKAGE_NAME}/config.py"
import os
import sys
import platform
from getpass import getpass
from pathlib import Path
from tempfile import gettempdir
from typing import Any, Dict, Optional, Union, cast
from click import UsageError

# Import and apply Apple Silicon optimizations if available
try:
    from .apple import optimize_for_apple_silicon
    IS_APPLE_SILICON = optimize_for_apple_silicon()
except ImportError:
    IS_APPLE_SILICON = False

# Define package-specific constants
PACKAGE_NAME: str = "llamasearch_ctrl"
COMMAND_NAME: str = "lsctrl"

# --- Path Configuration ---
# Use environment variables first, then fall back to defaults based on OS conventions.
def get_config_dir() -> Path:
    """Gets the base directory for configuration files."""
    if path_env := os.getenv("LLAMASEARCH_CTRL_CONFIG_DIR"):
        return Path(path_env).expanduser()
    if sys.platform == "win32":
        # Use %APPDATA% on Windows
        appdata = os.getenv("APPDATA")
        if appdata:
            return Path(appdata) / PACKAGE_NAME
        else:
            # Fallback if APPDATA isn't set (unusual)
            return Path.home() / ".config" / PACKAGE_NAME
    elif sys.platform == "darwin":
        # Use ~/Library/Application Support on macOS
        return Path.home() / "Library" / "Application Support" / PACKAGE_NAME
    else:
        # Use XDG_CONFIG_HOME or default to ~/.config on Linux/other POSIX
        xdg_config_home = os.getenv("XDG_CONFIG_HOME")
        if xdg_config_home:
            return Path(xdg_config_home) / PACKAGE_NAME
        else:
            return Path.home() / ".config" / PACKAGE_NAME

def get_cache_dir() -> Path:
    """Gets the base directory for cache files."""
    if path_env := os.getenv("LLAMASEARCH_CTRL_CACHE_DIR"):
        return Path(path_env).expanduser()
    if sys.platform == "win32":
        # Use %LOCALAPPDATA% on Windows
        localappdata = os.getenv("LOCALAPPDATA")
        if localappdata:
            return Path(localappdata) / PACKAGE_NAME / "Cache"
        else:
            return Path.home() / ".cache" / PACKAGE_NAME # Fallback
    elif sys.platform == "darwin":
        # Use ~/Library/Caches on macOS
        return Path.home() / "Library" / "Caches" / PACKAGE_NAME
    else:
        # Use XDG_CACHE_HOME or default to ~/.cache on Linux/other POSIX
        xdg_cache_home = os.getenv("XDG_CACHE_HOME")
        if xdg_cache_home:
            return Path(xdg_cache_home) / PACKAGE_NAME
        else:
            return Path.home() / ".cache" / PACKAGE_NAME

# Configuration paths based on detected or overridden base dirs
LLAMASEARCH_CTRL_CONFIG_FOLDER: Path = get_config_dir()
LLAMASEARCH_CTRL_CACHE_FOLDER: Path = get_cache_dir()
LLAMASEARCH_CTRL_CONFIG_PATH: Path = LLAMASEARCH_CTRL_CONFIG_FOLDER / f".{COMMAND_NAME}rc"
ROLE_STORAGE_PATH_DEFAULT: Path = LLAMASEARCH_CTRL_CONFIG_FOLDER / "roles"
FUNCTIONS_PATH_DEFAULT: Path = LLAMASEARCH_CTRL_CONFIG_FOLDER / "functions"

# Cache paths - use package-specific subdirectories in cache folder
CHAT_CACHE_PATH_DEFAULT: Path = LLAMASEARCH_CTRL_CACHE_FOLDER / "chats"
CACHE_PATH_DEFAULT: Path = LLAMASEARCH_CTRL_CACHE_FOLDER / "requests"

# Default configuration values, using environment variables as overrides
# Type hints help with understanding the expected types
DEFAULT_CONFIG: Dict[str, Any] = {
    # --- API Settings ---
    "OPENAI_API_KEY": os.getenv("OPENAI_API_KEY", None), # Gets from env, prompt if None later
    "API_BASE_URL": os.getenv("API_BASE_URL", "default"), # 'default', Ollama URL, etc.
    "DEFAULT_MODEL": os.getenv("DEFAULT_MODEL", "gpt-4o"), # Model name
    "USE_LITELLM": os.getenv("USE_LITELLM", "false").lower() == 'true', # Use LiteLLM proxy?
    # --- Cache Settings ---
    "CHAT_CACHE_PATH": os.getenv("CHAT_CACHE_PATH", str(CHAT_CACHE_PATH_DEFAULT)),
    "CACHE_PATH": os.getenv("CACHE_PATH", str(CACHE_PATH_DEFAULT)),
    "CHAT_CACHE_LENGTH": int(os.getenv("CHAT_CACHE_LENGTH", "100")),
    "CACHE_LENGTH": int(os.getenv("CACHE_LENGTH", "100")), # Use same default as chat
    # --- Request Settings ---
    "REQUEST_TIMEOUT": int(os.getenv("REQUEST_TIMEOUT", "60")),
    "DISABLE_STREAMING": os.getenv("DISABLE_STREAMING", "false").lower() == 'true',
    # --- Role and Function Settings ---
    "ROLE_STORAGE_PATH": os.getenv("ROLE_STORAGE_PATH", str(ROLE_STORAGE_PATH_DEFAULT)),
    "OPENAI_FUNCTIONS_PATH": os.getenv("OPENAI_FUNCTIONS_PATH", str(FUNCTIONS_PATH_DEFAULT)),
    "OPENAI_USE_FUNCTIONS": os.getenv("OPENAI_USE_FUNCTIONS", "true").lower() == 'true',
    "SHOW_FUNCTIONS_OUTPUT": os.getenv("SHOW_FUNCTIONS_OUTPUT", "false").lower() == 'true',
    # --- UI/UX Settings ---
    "DEFAULT_COLOR": os.getenv("DEFAULT_COLOR", "magenta"), # Rich color name
    "DEFAULT_EXECUTE_SHELL_CMD": os.getenv("DEFAULT_EXECUTE_SHELL_CMD", "false").lower() == 'true', # Auto-execute?
    "CODE_THEME": os.getenv("CODE_THEME", "dracula"), # Pygments theme
    "PRETTIFY_MARKDOWN": os.getenv("PRETTIFY_MARKDOWN", "true").lower() == 'true',
    "SHELL_INTERACTION": os.getenv("SHELL_INTERACTION", "true").lower() == 'true', # Shell prompt E/D/A?
    # --- System Information (used for prompts) ---
    "OS_NAME": os.getenv("OS_NAME", "