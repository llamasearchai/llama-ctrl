"""
Handler factory module for LlamaSearch Control.
Creates the appropriate handler instance based on context and system capabilities.
"""

from typing import Any, Dict, List, Optional, Type
from enum import Enum  # Added for dummy enum


# --- Dummy Placeholders for missing imports ---
class SystemRole(Enum):
    ASSISTANT = "assistant"
    USER = "user"
    # Add others if needed


class Handler:
    """Dummy Handler base class."""

    def __init__(
        self,
        role: SystemRole,
        markdown: bool,
        model: str,
        temperature: float,
        top_p: float,
        caching: bool,
        functions: Optional[List[Dict[str, Any]]],
        **kwargs,
    ):
        self.role = role
        # Store other args if needed


class ChatHandler(Handler):
    """Dummy ChatHandler."""

    def __init__(self, chat_id: str, **kwargs):
        super().__init__(**kwargs)
        self.chat_id = chat_id


class DefaultHandler(Handler):
    """Dummy DefaultHandler."""

    pass


class ReplHandler(Handler):
    """Dummy ReplHandler."""

    def __init__(self, chat_id: str, **kwargs):
        super().__init__(**kwargs)
        self.chat_id = chat_id


# --- End Dummy Placeholders ---

# Commented out missing imports
# from ..role import SystemRole
# from .chat_handler import ChatHandler
# from .default_handler import DefaultHandler
# from .handler import Handler
# from .repl_handler import ReplHandler

# Check if M3 optimization is available
try:
    from ..apple import IS_APPLE_SILICON, M3_MAX_OPTIMIZED
    from .m3_handler import M3OptimizedHandler

    M3_HANDLER_AVAILABLE = True
except ImportError:
    # If import fails, set flags to indicate optimizations aren't available
    IS_APPLE_SILICON = False
    M3_MAX_OPTIMIZED = False
    M3_HANDLER_AVAILABLE = False

    # Define M3OptimizedHandler as a dummy if import fails to avoid NameError
    class M3OptimizedHandler(Handler):  # Inherit from dummy Handler
        """Dummy M3OptimizedHandler when import fails."""

        pass


def create_handler(
    handler_type: str,
    role: SystemRole,
    *,
    chat_id: Optional[str] = None,
    markdown: bool = True,
    model: str = "gpt-4o",
    temperature: float = 0.1,
    top_p: float = 1.0,
    caching: bool = True,
    functions: Optional[List[Dict[str, Any]]] = None,
    **kwargs: Any,
) -> Handler:
    """
    Factory function that creates and returns the appropriate handler instance.

    Automatically selects the optimized M3 handler on Apple Silicon Macs when available.

    Args:
        handler_type: Type of handler ("default", "chat", "repl")
        role: The SystemRole to use for the handler
        chat_id: Session ID for chat/repl handlers (optional)
        markdown: Whether to render output as markdown
        model: The LLM model name to use
        temperature: Model temperature (randomness) parameter
        top_p: Model top-p sampling parameter
        caching: Whether to enable response caching
        functions: Optional list of function definitions for tool calling
        **kwargs: Additional keyword arguments to pass to the handler

    Returns:
        An instance of the appropriate Handler subclass
    """
    # Prepare common arguments for all handler types
    common_args = {
        "role": role,
        "markdown": markdown,
        "model": model,
        "temperature": temperature,
        "top_p": top_p,
        "caching": caching,
        "functions": functions,
        **kwargs,
    }

    # Determine if we should use the M3-optimized handler
    use_m3_handler = M3_HANDLER_AVAILABLE and IS_APPLE_SILICON

    # Check if this is a chat-based handler type
    is_chat_based = handler_type in ("chat", "repl")

    # Select the appropriate base class for instantiation
    if is_chat_based:
        # For chat-based handlers, we need the chat_id parameter
        if chat_id is None:
            raise ValueError(f"chat_id must be provided for {handler_type} handler")

        if handler_type == "repl":
            # Create REPL handler
            if use_m3_handler:
                # Use M3-optimized REPL handler by subclassing ReplHandler with M3OptimizedHandler
                class M3OptimizedReplHandler(M3OptimizedHandler, ReplHandler):
                    """REPL handler with M3 optimizations"""

                    pass

                return M3OptimizedReplHandler(chat_id=chat_id, **common_args)
            else:
                # Use standard REPL handler
                return ReplHandler(chat_id=chat_id, **common_args)
        else:  # "chat"
            # Create Chat handler
            if use_m3_handler:
                # Use M3-optimized Chat handler by subclassing ChatHandler with M3OptimizedHandler
                class M3OptimizedChatHandler(M3OptimizedHandler, ChatHandler):
                    """Chat handler with M3 optimizations"""

                    pass

                return M3OptimizedChatHandler(chat_id=chat_id, **common_args)
            else:
                # Use standard Chat handler
                return ChatHandler(chat_id=chat_id, **common_args)
    else:
        # Default handler (single-turn)
        if use_m3_handler:
            # Create M3-optimized default handler
            return M3OptimizedHandler(**common_args)
        else:
            # Create standard default handler
            return DefaultHandler(**common_args)


def create_handler_for_system(system_info: Dict[str, Any]) -> Type[Handler]:
    """
    Determines the best handler class for the current system.
    Used for type resolution and handler selection.

    Args:
        system_info: System information dictionary with processor details

    Returns:
        Handler class appropriate for the current system
    """
    # Check for Apple Silicon Mac
    if system_info.get("is_apple_silicon", False):
        if system_info.get("is_m3", False):
            # For M3 chips, use the optimized handler if available
            if M3_HANDLER_AVAILABLE:
                return M3OptimizedHandler
        # For other Apple Silicon, check if optimized handler is available
        if M3_HANDLER_AVAILABLE:
            return M3OptimizedHandler

    # Fall back to standard handler for other systems
    return DefaultHandler
