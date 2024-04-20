# LlamaSearch Control - Changelog

## v1.6.0 (Current Release) - March 2024

### 🚀 Major Features
- **M3 Max Optimizations**: Dedicated support for Apple Silicon M3 Max chips
- **Ollama Integration**: Seamless setup and configuration of Ollama for local LLM inference
- **Metal GPU Acceleration**: Utilizes Apple's Metal framework for faster inference
- **Neural Engine Support**: Experimental integration with Apple's Neural Engine
- **Enhanced Threading Model**: Optimized thread allocation for performance and efficiency cores

### 🧠 LLM Improvements
- **Llama 3 Support**: Optimized configuration for Llama 3 models
- **Local Model Management**: Simplified download and management of local LLM models
- **Performance Tuning**: Specialized parameters for M3 Max performance
- **Caching System**: Improved response caching with M3-optimized file operations

### 🛠️ Technical Improvements
- **Handler Factory**: Dynamic selection of optimized handlers based on system capabilities
- **M3 Handler**: Specialized handler class with Apple Silicon optimizations
- **Enhanced Streaming**: Better response streaming for improved user experience
- **Tool Integration**: Support for multi-threaded function calls and system operations

### 📱 Usability Improvements
- **Llama Graphics**: Added llama ASCII art throughout the interface
- **Installation Test Utility**: New test script to verify installation
- **Improved Documentation**: Enhanced README with M3 Max optimization details
- **Version Check System**: Automatic version checking for updates

## v1.5.0 - January 2024

### Major Features
- Apple Silicon support (general M1/M2 optimizations)
- Initial integration with Ollama
- Improved chat and REPL modes
- Shell command generation enhancements

### Technical Improvements
- Performance optimizations for Apple Silicon
- Better error handling
- Enhanced caching system

## v1.4.0 - November 2023

### Major Features
- Code generation improvements
- Custom roles system
- Shell integration with keyboard shortcuts
- Function calling capabilities

### Technical Improvements
- Better streaming response handling
- Markdown rendering enhancements
- Configuration system improvements

## v1.3.0 - September 2023

### Major Features
- Interactive REPL mode
- Chat sessions with context
- Improved command generation
- Initial Apple Silicon support

## v1.2.0 - July 2023

### Major Features
- Basic chat mode
- Code generation mode
- Model selection options
- Configuration file support

## v1.1.0 - May 2023

### Major Features
- Shell command generation
- Document analysis from stdin
- Basic query functionality
- Initial release based on ShellGPT

## v1.0.0 - April 2023

### Major Features
- Initial fork from ShellGPT
- Rebranding to LlamaSearch Control
- Basic functionality and infrastructure 