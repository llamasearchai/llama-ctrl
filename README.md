# llama-ctrl

[![PyPI version](https://img.shields.io/pypi/v/llama_ctrl.svg)](https://pypi.org/project/llama_ctrl/)
[![License](https://img.shields.io/github/license/llamasearchai/llama-ctrl)](https://github.com/llamasearchai/llama-ctrl/blob/main/LICENSE)
[![Python Version](https://img.shields.io/pypi/pyversions/llama_ctrl.svg)](https://pypi.org/project/llama_ctrl/)
[![CI Status](https://github.com/llamasearchai/llama-ctrl/actions/workflows/llamasearchai_ci.yml/badge.svg)](https://github.com/llamasearchai/llama-ctrl/actions/workflows/llamasearchai_ci.yml)

**Llama Control (llama-ctrl)** is a versatile command-line interface (CLI) and Python client library designed for interacting with and managing various LlamaSearch AI operations. It provides a unified entry point for controlling models, managing configurations, and executing tasks within the LlamaSearch ecosystem. The tool is optimized for different hardware, including Apple Silicon (M1/M2/M3), to ensure efficient performance.

## Key Features

- **Unified CLI Interface:** Control various LlamaSearch functions via a single `llama-ctrl` command.
- **Python Client Library:** Integrate control functionality directly into your Python applications.
- **Hardware Optimization:** Includes specific optimizations for Apple Silicon (M-series chips).
- **Request Handling:** Uses a factory pattern to dynamically select appropriate handlers (e.g., default, chat, REPL).
- **Caching:** Built-in file-based caching to speed up repeated operations (especially LLM calls).
- **Extensible:** Designed to be easily extended with new commands and handlers.

## Installation

```bash
pip install llama-ctrl
# Or install directly from GitHub for the latest version:
# pip install git+https://github.com/llamasearchai/llama-ctrl.git
```

## Usage

### Command-Line Interface (CLI)

The CLI provides various subcommands. Use `--help` to explore options:

```bash
llama-ctrl --help
llama-ctrl <command> --help
```

*(More specific CLI examples will be added as commands are finalized)*

### Python Client

```python
from llamasearch_ctrl import Client # Assuming Client class exists

# Initialize the client (configuration details might vary)
# client = Client(api_key="YOUR_API_KEY") # Example configuration
client = Client() # Basic initialization

# Example: Process some data or execute a command
# The exact methods will depend on the final API design
# result = client.execute_command("some_command", param="value")
# print(result)

# Example from original README (adjust class/method names if needed)
# from llamasearch_ctrl import LlamaCtrlClient
# client = LlamaCtrlClient(api_key="your-api-key")
# result = client.query("your query")
# print(result)
```
*(Note: The Python client API details need refinement based on the actual implementation in `src/llamasearch_ctrl`)*

## Architecture Overview

`llama-ctrl` follows a modular design:

```mermaid
graph TD
    A[CLI (Typer) / Python Client] --> B{Handler Factory};
    B -- Selects Handler --> C[Default Handler];
    B -- Selects Handler --> D[Chat Handler];
    B -- Selects Handler --> E[REPL Handler];
    B -- Selects Handler --> F[M3 Optimized Handler];
    B -- Selects Handler --> G[... other handlers];
    C --> H(Core Logic / LLM Interaction);
    D --> H;
    E --> H;
    F --> H;
    G --> H;
    H --> I[Cache System];
    A --> J[System Info (OS/CPU Detection)];
    J --> B;
    J --> F;

    style H fill:#f9f,stroke:#333,stroke-width:2px
    style I fill:#ccf,stroke:#333,stroke-width:1px
```

1.  **Entry Point:** User interacts via the CLI (`typer`) or Python client.
2.  **System Info:** Detects OS and CPU (e.g., Apple Silicon M3) for potential optimizations.
3.  **Handler Factory:** Selects the appropriate handler based on the command/context and system info.
4.  **Handlers:** Specific handlers (Default, Chat, REPL, M3-optimized, etc.) process the request.
5.  **Core Logic:** Handlers interact with the core LlamaSearch functionalities or LLMs.
6.  **Caching:** Results can be cached to improve performance for subsequent identical requests.

## Configuration

*(Details on configuration files, environment variables, or API keys needed by `llama-ctrl` will be added here.)*

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/llamasearchai/llama-ctrl.git
cd llama-ctrl

# Create and activate a virtual environment (recommended)
# python -m venv venv
# source venv/bin/activate # or .\venv\Scripts\activate on Windows

# Install in editable mode with development dependencies
pip install -e ".[dev]"
```

### Testing

```bash
pytest tests/
```

### Contributing

Contributions are welcome! Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Developed by lalamasearhc.*
