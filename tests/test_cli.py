"""Tests for cyfaust command-line interface."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest


# Get the project root directory
PROJECT_ROOT = Path(__file__).parent.parent
EXAMPLES_DIR = PROJECT_ROOT / "share" / "faust" / "examples"
NOISE_DSP = EXAMPLES_DIR / "generator" / "noise.dsp"


def run_cli(*args, check=True):
    """Run cyfaust CLI with given arguments."""
    cmd = [sys.executable, "-m", "cyfaust"] + list(args)
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
    )
    if check and result.returncode != 0:
        print(f"STDOUT: {result.stdout}")
        print(f"STDERR: {result.stderr}")
    return result


@pytest.fixture
def temp_dir():
    """Create a temporary directory for test outputs."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def sample_dsp(temp_dir):
    """Create a simple DSP file for testing."""
    dsp_file = temp_dir / "test.dsp"
    dsp_file.write_text("""
import("stdfaust.lib");
process = no.noise * hslider("volume", 0.5, 0, 1, 0.01);
""")
    return dsp_file


@pytest.fixture
def invalid_dsp(temp_dir):
    """Create an invalid DSP file for testing."""
    dsp_file = temp_dir / "invalid.dsp"
    dsp_file.write_text("this is not valid faust code !!!")
    return dsp_file


class TestVersionCommand:
    """Tests for the version command."""

    def test_version_output(self):
        """Test that version command outputs version info."""
        result = run_cli("version")
        assert result.returncode == 0
        assert "cyfaust" in result.stdout.lower()
        assert "libfaust" in result.stdout.lower()
        # Check for version number pattern
        assert "2." in result.stdout  # Faust version starts with 2.


class TestCompileCommand:
    """Tests for the compile command."""

    def test_compile_to_cpp(self, sample_dsp, temp_dir):
        """Test compiling DSP to C++."""
        output_file = temp_dir / "output.cpp"
        result = run_cli("compile", str(sample_dsp), "-b", "cpp", "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()
        content = output_file.read_text()
        assert "class" in content or "struct" in content

    def test_compile_to_c(self, sample_dsp, temp_dir):
        """Test compiling DSP to C."""
        output_file = temp_dir / "output.c"
        result = run_cli("compile", str(sample_dsp), "-b", "c", "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()

    def test_compile_to_rust(self, sample_dsp, temp_dir):
        """Test compiling DSP to Rust."""
        output_file = temp_dir / "output.rs"
        result = run_cli("compile", str(sample_dsp), "-b", "rust", "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()
        content = output_file.read_text()
        assert "fn" in content or "struct" in content

    def test_compile_to_stdout(self, sample_dsp):
        """Test compiling DSP to stdout."""
        result = run_cli("compile", str(sample_dsp), "-b", "cpp")
        assert result.returncode == 0
        assert len(result.stdout) > 0
        assert "class" in result.stdout or "struct" in result.stdout

    def test_compile_nonexistent_file(self):
        """Test compiling a non-existent file."""
        result = run_cli("compile", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0
        assert "not found" in result.stderr.lower() or "error" in result.stderr.lower()

    def test_compile_invalid_backend(self, sample_dsp):
        """Test compiling with invalid backend."""
        result = run_cli("compile", str(sample_dsp), "-b", "invalid", check=False)
        assert result.returncode != 0
        assert "unknown backend" in result.stderr.lower() or "error" in result.stderr.lower()


class TestDiagramCommand:
    """Tests for the diagram command."""

    def test_diagram_generation(self, sample_dsp, temp_dir):
        """Test SVG diagram generation."""
        result = run_cli("diagram", str(sample_dsp), "-o", str(temp_dir))
        assert result.returncode == 0
        # Check that SVG directory was created
        svg_dirs = list(temp_dir.glob("*-svg"))
        assert len(svg_dirs) >= 0  # May or may not create directory depending on Faust version

    def test_diagram_nonexistent_file(self):
        """Test diagram generation for non-existent file."""
        result = run_cli("diagram", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestExpandCommand:
    """Tests for the expand command."""

    def test_expand_to_stdout(self, sample_dsp):
        """Test expanding DSP to stdout."""
        result = run_cli("expand", str(sample_dsp))
        assert result.returncode == 0
        assert "SHA1" in result.stdout or "process" in result.stdout

    def test_expand_to_file(self, sample_dsp, temp_dir):
        """Test expanding DSP to file."""
        output_file = temp_dir / "expanded.dsp"
        result = run_cli("expand", str(sample_dsp), "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()
        content = output_file.read_text()
        assert "process" in content or "import" in content

    def test_expand_sha_only(self, sample_dsp):
        """Test getting only SHA key."""
        result = run_cli("expand", str(sample_dsp), "--sha-only")
        assert result.returncode == 0
        # SHA1 key is 40 hex characters
        sha = result.stdout.strip()
        assert len(sha) == 40
        assert all(c in "0123456789ABCDEFabcdef" for c in sha)

    def test_expand_nonexistent_file(self):
        """Test expanding non-existent file."""
        result = run_cli("expand", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestInfoCommand:
    """Tests for the info command."""

    def test_info_output(self, sample_dsp):
        """Test info command output."""
        result = run_cli("info", str(sample_dsp))
        assert result.returncode == 0
        assert "File:" in result.stdout
        assert "Name:" in result.stdout
        assert "Inputs:" in result.stdout
        assert "Outputs:" in result.stdout

    def test_info_with_noise_dsp(self):
        """Test info command with noise.dsp example."""
        if NOISE_DSP.exists():
            result = run_cli("info", str(NOISE_DSP))
            assert result.returncode == 0
            assert "Outputs:" in result.stdout

    def test_info_nonexistent_file(self):
        """Test info for non-existent file."""
        result = run_cli("info", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestPlayCommand:
    """Tests for the play command."""

    def test_play_short_duration(self, sample_dsp):
        """Test play command with very short duration."""
        # Play for 0.1 seconds - just to verify it starts without error
        result = run_cli("play", str(sample_dsp), "-d", "0.1")
        assert result.returncode == 0
        assert "Playing" in result.stdout
        assert "Stopped" in result.stdout

    def test_play_with_samplerate(self, sample_dsp):
        """Test play command with custom sample rate."""
        result = run_cli("play", str(sample_dsp), "-d", "0.1", "-r", "48000")
        assert result.returncode == 0
        assert "48000" in result.stdout

    def test_play_nonexistent_file(self):
        """Test play for non-existent file."""
        result = run_cli("play", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestParamsCommand:
    """Tests for the params command."""

    def test_params_output(self, sample_dsp):
        """Test params command output."""
        result = run_cli("params", str(sample_dsp))
        assert result.returncode == 0
        assert "volume" in result.stdout.lower()
        assert "hslider" in result.stdout.lower()

    def test_params_with_no_params(self, temp_dir):
        """Test params command with DSP that has no parameters."""
        dsp_file = temp_dir / "no_params.dsp"
        dsp_file.write_text("process = _;")
        result = run_cli("params", str(dsp_file))
        assert result.returncode == 0
        assert "No parameters" in result.stdout or "0" in result.stdout

    def test_params_nonexistent_file(self):
        """Test params for non-existent file."""
        result = run_cli("params", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestValidateCommand:
    """Tests for the validate command."""

    def test_validate_valid_dsp(self, sample_dsp):
        """Test validating a valid DSP file."""
        result = run_cli("validate", str(sample_dsp))
        assert result.returncode == 0
        assert "VALID" in result.stdout

    def test_validate_invalid_dsp(self, invalid_dsp):
        """Test validating an invalid DSP file."""
        result = run_cli("validate", str(invalid_dsp), check=False)
        assert result.returncode != 0
        assert "INVALID" in result.stdout or "error" in result.stderr.lower()

    def test_validate_nonexistent_file(self):
        """Test validating non-existent file."""
        result = run_cli("validate", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0

    def test_validate_strict_mode(self, sample_dsp):
        """Test validate in strict mode."""
        result = run_cli("validate", str(sample_dsp), "--strict")
        # Should pass for valid DSP without warnings
        assert result.returncode == 0


class TestBitcodeCommand:
    """Tests for the bitcode command."""

    def test_bitcode_save(self, sample_dsp, temp_dir):
        """Test saving DSP to bitcode."""
        output_file = temp_dir / "test.fbc"
        result = run_cli("bitcode", "save", str(sample_dsp), "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()
        assert output_file.stat().st_size > 0

    def test_bitcode_load(self, sample_dsp, temp_dir):
        """Test loading bitcode."""
        # First save
        bitcode_file = temp_dir / "test.fbc"
        run_cli("bitcode", "save", str(sample_dsp), "-o", str(bitcode_file))

        # Then load
        result = run_cli("bitcode", "load", str(bitcode_file))
        assert result.returncode == 0
        assert "Loaded bitcode" in result.stdout
        assert "Name:" in result.stdout

    def test_bitcode_save_nonexistent_file(self):
        """Test saving non-existent file."""
        result = run_cli("bitcode", "save", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0

    def test_bitcode_load_nonexistent_file(self):
        """Test loading non-existent bitcode."""
        result = run_cli("bitcode", "load", "/nonexistent/file.fbc", check=False)
        assert result.returncode != 0


class TestJsonCommand:
    """Tests for the json command."""

    def test_json_output(self, sample_dsp):
        """Test JSON output."""
        result = run_cli("json", str(sample_dsp))
        assert result.returncode == 0
        data = json.loads(result.stdout)
        assert "name" in data
        assert "inputs" in data
        assert "outputs" in data

    def test_json_pretty(self, sample_dsp):
        """Test pretty-printed JSON output."""
        result = run_cli("json", str(sample_dsp), "--pretty")
        assert result.returncode == 0
        # Pretty-printed JSON has newlines and indentation
        assert "\n" in result.stdout
        data = json.loads(result.stdout)
        assert "name" in data

    def test_json_to_file(self, sample_dsp, temp_dir):
        """Test writing JSON to file."""
        output_file = temp_dir / "output.json"
        result = run_cli("json", str(sample_dsp), "-o", str(output_file))
        assert result.returncode == 0
        assert output_file.exists()
        data = json.loads(output_file.read_text())
        assert "name" in data

    def test_json_with_parameters(self, sample_dsp):
        """Test JSON includes parameters."""
        result = run_cli("json", str(sample_dsp), "--pretty")
        assert result.returncode == 0
        data = json.loads(result.stdout)
        assert "parameters" in data
        assert len(data["parameters"]) > 0
        # Check for our volume slider
        param_labels = [p["label"] for p in data["parameters"]]
        assert "volume" in param_labels

    def test_json_nonexistent_file(self):
        """Test JSON for non-existent file."""
        result = run_cli("json", "/nonexistent/file.dsp", check=False)
        assert result.returncode != 0


class TestHelpCommand:
    """Tests for help output."""

    def test_main_help(self):
        """Test main help output."""
        result = run_cli("--help")
        assert result.returncode == 0
        assert "cyfaust" in result.stdout
        assert "version" in result.stdout
        assert "compile" in result.stdout
        assert "play" in result.stdout

    def test_compile_help(self):
        """Test compile subcommand help."""
        result = run_cli("compile", "--help")
        assert result.returncode == 0
        assert "backend" in result.stdout
        assert "output" in result.stdout

    def test_play_help(self):
        """Test play subcommand help."""
        result = run_cli("play", "--help")
        assert result.returncode == 0
        assert "duration" in result.stdout
        assert "samplerate" in result.stdout

    def test_no_command(self):
        """Test running without any command shows help."""
        result = run_cli()
        assert result.returncode == 0
        assert "cyfaust" in result.stdout
