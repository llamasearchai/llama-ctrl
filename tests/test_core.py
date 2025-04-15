"""Basic tests for the llama-ctrl package and CLI."""

import pytest
from typer.testing import CliRunner

# Try importing the package and the CLI app
try:
    import llama_ctrl
    from llama_ctrl.cli import app as cli_app
except ImportError as e:
    pytest.fail(f"Failed to import llama_ctrl or cli_app: {e}", pytrace=False)

runner = CliRunner()


def test_import():
    """Test that the main package can be imported."""
    assert llama_ctrl is not None


def test_version():
    """Test that the package has a version attribute."""
    assert hasattr(llama_ctrl, "__version__")
    assert isinstance(llama_ctrl.__version__, str)


def test_cli_version():
    """Test the CLI --version option."""
    result = runner.invoke(cli_app, ["--version"])
    assert result.exit_code == 0
    assert llama_ctrl.__version__ in result.stdout


def test_cli_status_placeholder():
    """Test the placeholder status command."""
    result = runner.invoke(cli_app, ["status"])
    assert result.exit_code == 0
    assert "Checking status" in result.stdout
    assert "(Placeholder: Implement actual status check)" in result.stdout


def test_cli_apply_placeholder():
    """Test the placeholder apply command requires --file."""
    result_no_file = runner.invoke(cli_app, ["apply"])
    assert result_no_file.exit_code != 0  # Should fail without --file
    assert "Missing option '--file' / '-f'" in result_no_file.stdout

    # Test with a dummy file path (doesn't need to exist for placeholder)
    result_with_file = runner.invoke(cli_app, ["apply", "--file", "dummy.yaml"])
    assert result_with_file.exit_code == 0
    assert "Applying configuration from: dummy.yaml" in result_with_file.stdout
    assert (
        "(Placeholder: Implement actual config application)" in result_with_file.stdout
    )


# Add more tests later:
# - Test configuration loading logic
# - Test interactions with mocked services (via httpx mocks or similar)
# - Test CLI commands with various arguments and options
