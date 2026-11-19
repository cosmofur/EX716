#!/usr/bin/env python3
"""Classic, non-segmented EX716 interpreter entry point."""

import importlib.util
from pathlib import Path
import sys


def _load_cpu_base():
    base_path = Path(__file__).with_name("cpu_base.py")
    module_name = "_ex716_cpu_base_classic"
    spec = importlib.util.spec_from_file_location(module_name, base_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load shared CPU implementation: {base_path}")
    module = importlib.util.module_from_spec(spec)
    module.CPU_PROFILE = "classic"
    module.LAUNCHER_FILE = __file__
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


_cpu_base = _load_cpu_base()

if __name__ == "__main__":
    _cpu_base.main()
else:
    # Keep the historical import surface (cpu.microcpu, cpu.OPTDICT, etc.)
    # and ensure assignments made by callers update the implementation globals.
    sys.modules[__name__] = _cpu_base
