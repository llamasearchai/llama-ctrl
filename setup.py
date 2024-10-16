#!/usr/bin/env python3
"""
Llama Ctrl - Python package for LlamaSearch AI
"""

from setuptools import setup, find_packages

setup(
    name="llama_ctrl",
    version="0.1.0",
    description="[![PyPI version](https://badge.fury.io/py/llama-ctrl.svg)](https://badge.fury.io/py/llama-ctrl)
[![Python Version](https://img.shields.io/pypi/pyversions/llama-ctrl.svg)](https://pypi.org/project/llama-ctrl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/yourusername/llama-ctrl-pkg/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/llama-ctrl-pkg/actions/workflows/ci.yml)",
    long_description="""# llama-ctrl

[![PyPI version](https://badge.fury.io/py/llama-ctrl.svg)](https://badge.fury.io/py/llama-ctrl)
[![Python Version](https://img.shields.io/pypi/pyversions/llama-ctrl.svg)](https://pypi.org/project/llama-ctrl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/yourusername/llama-ctrl-pkg/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/llama-ctrl-pkg/actions/workflows/ci.yml)

## Installation

```bash
pip install -e .
```

## Usage

```python
from llama_ctrl import LlamaCtrlClient

# Initialize the client
client = LlamaCtrlClient(api_key="your-api-key")
result = client.query("your query")
print(result)
```

## Features

- Fast and efficient
- Easy to use API
- Comprehensive documentation
- Asynchronous support
- Built-in caching

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/nikjois/llama-ctrl.git
cd llama-ctrl

# Install development dependencies
pip install -e ".[dev]"
```

### Testing

```bash
pytest
```

## License

MIT

## Author

Nik Jois (nikjois@llamasearch.ai)
""",
    long_description_content_type="text/markdown",
    author="Nik Jois",
    author_email="nikjois@llamasearch.ai",
    url="https://github.com/llamasearchai/llama-ctrl",
    project_urls={
        "Documentation": "https://github.com/llamasearchai/llama-ctrl",
        "Bug Tracker": "https://github.com/llamasearchai/llama-ctrl/issues",
        "Source Code": "https://github.com/llamasearchai/llama-ctrl",
    },
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
)
