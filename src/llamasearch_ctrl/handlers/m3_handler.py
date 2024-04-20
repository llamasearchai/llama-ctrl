import json
import queue
import sys
import threading
import time
from typing import Any, Dict, Generator, List, Optional

from ..apple import IS_APPLE_SILICON, M3_MAX_OPTIMIZED


# --- Dummy Placeholders for missing imports ---
class Config:
    def get(self, key, default=None):
        # Basic dummy config get
        if key == "API_BASE_URL":
            return "dummy_url"
        if key == "USE_LITELLM":
            return False
        if key == "OPENAI_API_KEY":
            return "dummy_key"
        return default


cfg = Config()  # Dummy cfg instance


class APIError(Exception):
    """Dummy APIError."""

    status_code: int = 500


# Assuming ChatMessage is a TypedDict or similar
ChatMessage = Dict[str, Any]


# Dummy llm_completion function (generator)
def llm_completion(**kwargs) -> Generator[Dict, None, None]:
    """Dummy LLM completion stream."""
    yield {"choices": [{"delta": {"content": "Dummy completion stream... "}}]}
    yield {"choices": [{"delta": {}, "finish_reason": "stop"}]}


# Dummy get_function
_dummy_functions = {"dummy_tool": lambda **kwargs: f"Executed dummy_tool with {kwargs}"}


def get_function(name: str) -> callable:
    """Dummy function getter."""
    func = _dummy_functions.get(name)
    if func is None:
        raise ValueError(f"Function '{name}' not found")
    return func


# Import dummy Handler from factory (assuming factory defines it)
# We need to handle the case where factory.py might not have been processed yet
# or if M3OptimizedHandler itself is defined as a dummy in factory
try:
    # Attempt to import the potentially dummy Handler from factory
    from .factory import Handler
except ImportError:
    # Fallback to defining a dummy Handler here if factory import fails
    class Handler:
        """Dummy Handler base class (fallback)."""

        def __init__(self, role, markdown, model, temperature, top_p, caching, functions, **kwargs):
            self.role = role
            self.markdown = markdown
            self.model = model
            self.temperature = temperature
            self.top_p = top_p
            self.caching = caching
            self.functions = functions
            self.allow_function_calling = functions is not None
            self.show_function_output = True  # Dummy value

        def _get_completion_from_provider(
            self, messages: List[ChatMessage], **kwargs: Any
        ) -> Generator[str, None, None]:
            yield "Dummy base completion."

        def _handle_function_call(
            self, messages: List[ChatMessage], tool_calls: List[Any]
        ) -> Generator[str, None, None]:
            yield "Dummy base function call handling."

        def _normalize_tool_calls(self, requested_tool_calls: List[Any]) -> List[Any]:
            return requested_tool_calls  # Dummy implementation


# --- End Dummy Placeholders ---

# Commented out original imports for now
# from ..config import cfg
# from .handler import APIError, ChatMessage, Handler, llm_completion


class M3OptimizedHandler(Handler):
    """
    Optimized handler for M3 Mac with improved performance characteristics.
    Uses threading for request preparation and background operations.

    This handler inherits from the base Handler and overrides key methods
    for better performance on Apple Silicon M3 architecture.
    """

    def __init__(self, *args, **kwargs):
        """Initialize the M3 optimized handler with threading capabilities."""
        super().__init__(*args, **kwargs)

        # Only use optimizations if running on Apple Silicon
        self._use_optimizations = IS_APPLE_SILICON
        self._is_m3_max = M3_MAX_OPTIMIZED if "M3_MAX_OPTIMIZED" in globals() else False

        # Performance tuning parameters
        self._completion_threads = 2  # Number of threads for multi-part completions
        self._token_chunk_size = 32  # Token chunk size for optimal M3 processing

        # Setup background queue for prefetching and other tasks
        self._background_queue = queue.Queue() if self._use_optimizations else None
        self._background_thread = None

        if self._use_optimizations:
            # Start background worker thread for M3 optimization
            self._background_thread = threading.Thread(
                target=self._background_worker, daemon=True, name="M3OptimizerThread"
            )
            self._background_thread.start()

    def _background_worker(self):
        """Background thread for processing optimizations for M3 chips."""
        if not self._background_queue:
            return

        while True:
            try:
                # Get task from queue with timeout to allow checking for exit
                task, args, kwargs = self._background_queue.get(timeout=1.0)
                try:
                    task(*args, **kwargs)
                except Exception as e:
                    print(f"[WARNING] Background task error: {e}", file=sys.stderr)
                finally:
                    self._background_queue.task_done()
            except queue.Empty:
                # No tasks, continue waiting
                continue
            except Exception as e:
                print(f"[ERROR] Background worker error: {e}", file=sys.stderr)
                # Sleep briefly to avoid high CPU if persistent error
                time.sleep(0.1)

    def _get_completion_from_provider(
        self, messages: List[ChatMessage], **kwargs: Any
    ) -> Generator[str, None, None]:
        """
        Enhanced version of the API call method optimized for M3 Mac performance.
        Uses threading and optimized buffer sizes for better throughput.
        """
        # If not on Apple Silicon, use the standard implementation
        if not self._use_optimizations:
            yield from super()._get_completion_from_provider(messages, **kwargs)
            return

        # M3-optimized implementation
        api_kwargs: Dict[str, Any] = {
            "model": self.model,
            "temperature": self.temperature,
            "top_p": self.top_p,
            "messages": messages,
            "stream": True,
        }

        # Special performance optimizations for M3 Max
        if self._is_m3_max:
            # Add M3 Max specific optimizations
            # Increase timeout for complex operations
            kwargs_timeout = kwargs.get("timeout", 60)
            api_kwargs["timeout"] = max(kwargs_timeout, 90)  # Ensure timeout is sufficient

            # Optimize token processing for the M3 Max architecture
            if "llama" in self.model.lower() or "mistral" in self.model.lower():
                # Optimize chunking for local models on M3
                api_kwargs["chunk_size"] = self._token_chunk_size

        # Add common arguments
        api_kwargs.update(kwargs)

        # Configure function calling if enabled
        if self.allow_function_calling and self.functions:
            api_kwargs["tools"] = self.functions
            api_kwargs["tool_choice"] = "auto"

        # Handle API base URL for LiteLLM if needed
        api_base_url = cfg.get("API_BASE_URL")
        if cfg.get("USE_LITELLM") and api_base_url and api_base_url != "default":
            api_kwargs["base_url"] = api_base_url
            # Pass API key if configured for LiteLLM
            api_key = cfg.get("OPENAI_API_KEY")
            if api_key and api_key != "api_key_not_set":
                api_kwargs["api_key"] = api_key

        # --- API Call and Streaming ---
        response_iterator: Optional[Any] = None
        try:
            # Make the API call
            response_iterator = llm_completion(**api_kwargs)

            accumulated_content: str = ""
            finish_reason: Optional[str] = None
            requested_tool_calls: List[Any] = []

            # Process chunks with optimizations for M3 chips
            for chunk in response_iterator:
                # --- Extract Delta and Finish Reason ---
                delta: Optional[Dict | object] = None
                chunk_finish_reason: Optional[str] = None

                try:
                    if hasattr(chunk, "choices") and chunk.choices:
                        # OpenAI client style
                        choice = chunk.choices[0]
                        delta = choice.delta
                        chunk_finish_reason = choice.finish_reason
                    elif isinstance(chunk, dict) and chunk.get("choices"):
                        # LiteLLM dict style
                        choice = chunk["choices"][0]
                        delta = choice.get("delta")
                        chunk_finish_reason = choice.get("finish_reason")
                    else:
                        continue  # Skip unrecognized chunk

                    if delta is None:
                        continue  # Skip if delta is missing
                except (AttributeError, IndexError, KeyError, TypeError):
                    continue  # Skip parsing errors

                # --- Process Delta Content ---
                chunk_content: Optional[str] = None

                # Access content attribute/key robustly
                if hasattr(delta, "content"):
                    chunk_content = delta.content
                elif isinstance(delta, dict):
                    chunk_content = delta.get("content")

                if chunk_content:
                    accumulated_content += chunk_content
                    yield chunk_content

                # --- Accumulate Tool Calls ---
                tool_calls_delta: Optional[List[Any]] = None
                if hasattr(delta, "tool_calls"):
                    tool_calls_delta = delta.tool_calls
                elif isinstance(delta, dict):
                    tool_calls_delta = delta.get("tool_calls")

                if tool_calls_delta:
                    requested_tool_calls.extend(tool_calls_delta)

                # --- Check Finish Reason ---
                if chunk_finish_reason:
                    finish_reason = chunk_finish_reason

                    # Handle tool calls
                    if finish_reason == "tool_calls":
                        final_tool_calls = self._normalize_tool_calls(requested_tool_calls)
                        if final_tool_calls:
                            # M3-optimized: Process tool calls with thread if complex
                            if len(final_tool_calls) > 1 and self._is_m3_max:
                                # Use threading for multiple tool calls on M3 Max
                                yield from self._process_tool_calls_threaded(
                                    messages, final_tool_calls
                                )
                            else:
                                # Use standard processing for single tool call
                                yield from self._handle_function_call(messages, final_tool_calls)
                            return  # Stop processing this stream after handling tool call
                        else:
                            yield "[ERROR] LLM indicated tool calls, but no valid calls were parsed.\n"

                    # Handle other finish reasons
                    if finish_reason == "stop":
                        pass  # Normal completion
                    elif finish_reason == "length":
                        yield "\n[WARNING] Response truncated by model due to length limit.\n"
                    elif finish_reason == "content_filter":
                        yield "\n[WARNING] Response stopped by content filter.\n"
                    else:
                        yield f"\n[INFO] Response finished with reason: {finish_reason}\n"

                    break  # Exit loop once finish reason is found

            # After loop - check if response was empty
            if not accumulated_content and not requested_tool_calls:
                yield "\n[WARNING] API Stream ended without content or finish reason.\n"

        except APIError as e_api:
            # Handle API errors
            status_code_info = (
                f" (Status: {getattr(e_api, 'status_code', 'N/A')})"
                if hasattr(e_api, "status_code")
                else ""
            )
            error_message = (
                f"\n[ERROR] API Error{status_code_info}: {type(e_api).__name__}: {e_api}\n"
            )
            yield error_message
            return
        except Exception as e_general:
            # Handle general errors with more helpful messages
            error_message = (
                f"\n[ERROR] API request failed: {type(e_general).__name__}: {e_general}\n"
            )

            # Check for common errors
            err_str = str(e_general).lower()
            if isinstance(e_general, TimeoutError) or "timed out" in err_str:
                error_message = f"\n[ERROR] API request timed out after {api_kwargs.get('timeout', 60)} seconds.\n"
            elif "connection refused" in err_str or "connection error" in err_str:
                endpoint_url = api_kwargs.get("base_url", api_base_url or "Default URL")
                error_message = f"\n[ERROR] Could not connect to API endpoint. Is the server running? ({endpoint_url})\n"

            yield error_message
            return
        finally:
            # Cleanup with proper error handling
            if (
                response_iterator
                and hasattr(response_iterator, "close")
                and callable(response_iterator.close)
            ):
                try:
                    response_iterator.close()
                except Exception:
                    pass

    def _process_tool_calls_threaded(
        self, messages: List[ChatMessage], tool_calls: List[Any]
    ) -> Generator[str, None, None]:
        """
        Process multiple tool calls using multiple threads for better M3 performance.
        Only used on M3 Max when multiple tool calls are requested.
        """
        # Add the assistant's message containing the tool_calls request
        assistant_message: ChatMessage = {"role": "assistant", "content": None}

        # Format tool calls for the message
        try:
            tool_calls_for_message = [
                tc.model_dump(mode="json") if hasattr(tc, "model_dump") else tc for tc in tool_calls
            ]
            assistant_message["tool_calls"] = tool_calls_for_message
        except Exception as e_tc_dump:
            yield f"[WARN] Could not properly format tool calls for message history: {e_tc_dump}\n"
            assistant_message["tool_calls"] = repr(tool_calls)

        # Add message to history
        messages.append(assistant_message)

        # Create a threaded execution queue
        results_queue = queue.Queue()
        threads = []

        # Start a new line before function calls
        yield "\n"

        # Process each tool call in a separate thread
        for i, tool_call in enumerate(tool_calls):
            # Extract tool call info
            function_name = ""
            function_args_str = ""
            tool_call_id = f"tool_{time.time_ns()}_{i}"  # Default ID with index

            try:
                # Extract info based on format
                if hasattr(tool_call, "function") and hasattr(tool_call, "id"):
                    function_name = getattr(tool_call.function, "name", "")
                    function_args_str = getattr(tool_call.function, "arguments", "")
                    tool_call_id = getattr(tool_call, "id", tool_call_id)
                elif isinstance(tool_call, dict) and "function" in tool_call:
                    function_name = tool_call.get("function", {}).get("name", "")
                    function_args_str = tool_call.get("function", {}).get("arguments", "")
                    tool_call_id = tool_call.get("id", tool_call_id)

                # Skip invalid tool calls
                if not function_name:
                    yield f"[WARNING] Skipping tool call with missing function name (ID: {tool_call_id}).\n"
                    continue

                # Show function call in progress
                yield f"> @FunctionCall `{function_name}` (ID: {tool_call_id})\n"

                # Create thread to process this tool call
                thread = threading.Thread(
                    target=self._execute_tool_call_thread,
                    args=(
                        function_name,
                        function_args_str,
                        tool_call_id,
                        results_queue,
                    ),
                    daemon=True,
                    name=f"ToolCallThread-{i}",
                )
                threads.append(thread)
                thread.start()

            except Exception as e:
                yield f"[ERROR] Failed to process tool call {tool_call_id}: {e}\n"
                results_queue.put(
                    (
                        tool_call_id,
                        function_name or "unknown_function",
                        f"Error processing tool call: {e}",
                    )
                )

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Collect results in order
        function_results = []
        while not results_queue.empty():
            tool_call_id, func_name, result = results_queue.get()

            # Add to function results list
            function_results.append(
                {
                    "tool_call_id": tool_call_id,
                    "role": "tool",
                    "name": func_name,
                    "content": result,
                }
            )

            # Show output if configured
            if self.show_function_output:
                output_display = f" Output:\n```text\n{result}\n```\n"
                yield output_display

        # Add all function results to messages
        messages.extend(function_results)

        # Make the recursive call with function results
        yield from self._get_completion_from_provider(messages=messages)

    def _execute_tool_call_thread(
        self,
        function_name: str,
        function_args_str: str,
        tool_call_id: str,
        results_queue,
    ):
        """Thread worker to execute a single tool call and put results in the queue."""
        result = ""

        try:
            # Parse arguments
            arguments = json.loads(function_args_str)
            if not isinstance(arguments, dict):
                raise json.JSONDecodeError(
                    "Arguments decoded to non-dict type", function_args_str, 0
                )

            # Import function dynamically here to avoid potential circular imports
            from ..function import get_function

            # Get and execute function
            execute_func = get_function(function_name)
            result_obj = execute_func(**arguments)
            result = str(result_obj) if result_obj is not None else "(No output)"

        except json.JSONDecodeError as json_err:
            result = f"Error: Invalid JSON arguments received: {json_err}"
        except ValueError:
            result = f"Error: Function '{function_name}' not found or not loaded."
        except TypeError as te:
            result = f"Error calling function {function_name}: Argument mismatch - {te}"
        except Exception as e_exec:
            result = f"Error during function execution: {type(e_exec).__name__}: {e_exec}"

        # Put result in queue
        results_queue.put((tool_call_id, function_name, result))
