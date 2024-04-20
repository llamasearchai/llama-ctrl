# Key integration changes for app.py

# Remove direct imports of handler classes
# from .handlers.default_handler import DefaultHandler
# from .handlers.chat_handler import ChatHandler
# from .handlers.repl_handler import ReplHandler

import platform
import sys
import typer

from .apple import IS_APPLE_SILICON, optimize_for_apple_silicon

# Instead, import the handler factory
from .handlers.handler_factory import create_handler


# Detect M3 series CPU
def is_m3_processor():
    """Check if the current Mac is using an M3 series processor."""
    if not IS_APPLE_SILICON:
        return False

    try:
        import subprocess

        result = subprocess.run(
            ["sysctl", "-n", "machdep.cpu.brand_string"],
            capture_output=True,
            text=True,
            check=True,
        )
        cpu_info = result.stdout.strip()
        return "M3" in cpu_info
    except:
        return False


# Initialize system information early
def initialize_system_info():
    """Initialize system information and apply optimizations."""
    system_info = {
        "os": platform.system(),
        "machine": platform.machine(),
        "is_apple_silicon": IS_APPLE_SILICON,
        "is_m3": is_m3_processor(),
    }

    # Apply Apple Silicon optimizations if applicable
    if system_info["is_apple_silicon"]:
        optimize_for_apple_silicon()
        print(
            f"[INFO] Applied Apple Silicon optimizations for {system_info['machine']}",
            file=sys.stderr,
        )

        if system_info["is_m3"]:
            print(
                "[INFO] M3 processor detected, using enhanced optimizations",
                file=sys.stderr,
            )

    return system_info


# Call this at application startup
SYSTEM_INFO = initialize_system_info()

# --- Handler Creation Logic ---
# Replace handler creation in main() with factory calls:


# Example implementation for main() handler creation:
def create_appropriate_handler(repl_session, chat_session, role, handler_kwargs):
    """Create the appropriate handler based on mode and system."""
    try:
        if repl_session:
            handler = create_handler("repl", role=role, chat_id=repl_session, **handler_kwargs)
        elif chat_session:
            handler = create_handler("chat", role=role, chat_id=chat_session, **handler_kwargs)
        else:
            # Default handler for single-turn requests
            handler = create_handler("default", role=role, **handler_kwargs)
        return handler
    except Exception as e:
        print(f"\n[ERROR] Failed to initialize command handler: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        raise typer.Exit(code=1)
