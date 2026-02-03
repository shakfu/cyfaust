import os
import sys

# On Windows, add DLL search path for faust.dll
if sys.platform == "win32":
    _dll_dirs = [
        os.path.dirname(__file__),  # Same directory (delvewheel bundles here)
    ]

    # For development: look for project lib folder by checking common locations
    # This handles editable installs and running from source
    _project_markers = ["pyproject.toml", "CMakeLists.txt"]
    _check_dir = os.path.dirname(__file__)
    for _ in range(10):  # Traverse up to 10 levels
        _parent = os.path.dirname(_check_dir)
        if _parent == _check_dir:  # Reached root
            break
        _check_dir = _parent
        # Check if this looks like the project root
        if any(os.path.isfile(os.path.join(_check_dir, m)) for m in _project_markers):
            _lib_dir = os.path.join(_check_dir, "lib")
            if os.path.isdir(_lib_dir):
                _dll_dirs.append(_lib_dir)
            break

    for _dll_dir in _dll_dirs:
        _dll_path = os.path.abspath(_dll_dir)
        if os.path.isfile(os.path.join(_dll_path, "faust.dll")):
            os.add_dll_directory(_dll_path)
            break

from .interp import get_version
