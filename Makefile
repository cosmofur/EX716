PYTHON ?= python3
DEBUG ?= 1

EXT_SRC := speedCPU.c vm_events.c vm_console.c exgc_device.c exgc_sixel.c
EXT_NAME := cpuCfunc
PLATFORM := $(shell $(PYTHON) -c "import os; print(os.name)")
EXT_SUFFIX := $(shell $(PYTHON) -c "import os, sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX') or ('.pyd' if os.name == 'nt' else '.so'))")
EXT_TARGET := $(EXT_NAME)$(EXT_SUFFIX)
LEGACY_EXT_TARGET := $(EXT_NAME).so
EXGC_SIXEL_DEMO := exgc_sixel_test
EXGC_SIXEL_UNIT := test_exgc_sixel

CC ?= $(shell $(PYTHON) -c "import shlex, sysconfig; print(shlex.split(sysconfig.get_config_var('CC') or 'cc')[0])")
PY_CFLAGS := $(shell $(PYTHON) -c "import sysconfig; print(' '.join('-I' + p for p in dict.fromkeys(filter(None, [sysconfig.get_path('include'), sysconfig.get_path('platinclude')]))))")
PY_LDFLAGS := $(shell $(PYTHON) -c "import sysconfig; print((sysconfig.get_config_var('LDFLAGS') or '') + ' ' + (sysconfig.get_config_var('LIBS') or '') + ' ' + (sysconfig.get_config_var('SYSLIBS') or ''))")
NUMPY_INCLUDE := $(shell $(PYTHON) -c "import numpy; print(numpy.get_include())")

WARNFLAGS := -Wall -Werror
DEBUGFLAGS := -O0 -g
OPTFLAGS := -O2 -DNDEBUG -Wno-cpp
COMMON_CFLAGS := $(WARNFLAGS) $(PY_CFLAGS) -I$(NUMPY_INCLUDE) -DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION

ifeq ($(DEBUG),1)
  BUILD_CFLAGS := $(DEBUGFLAGS)
else
  BUILD_CFLAGS := $(OPTFLAGS)
endif

ifeq ($(PLATFORM),nt)
  EXTENSION_SUPPORTED := 0
  SHARED_FLAGS := -shared
else
  EXTENSION_SUPPORTED := 1
  SHARED_FLAGS := -shared -fPIC
endif

.PHONY: all extension check test exgc-sixel test-exgc-sixel test-exgc-device benchmark-exgc-sixel clean help

all: extension

extension: $(EXT_TARGET)

$(EXT_TARGET): $(EXT_SRC) speedCPU.h vm_events.h vm_console.h exgc_device.h exgc_sixel.h
ifeq ($(EXTENSION_SUPPORTED),0)
	$(error Native Windows builds of $(EXT_NAME) are not supported yet because $(EXT_SRC) uses POSIX terminal APIs. Use WSL/Linux/Termux, or run cpu.py without -f)
else
	$(CC) $(SHARED_FLAGS) $(EXT_SRC) $(COMMON_CFLAGS) $(BUILD_CFLAGS) $(PY_LDFLAGS) -o $@
	$(PYTHON) -c "import pathlib, shutil; src=pathlib.Path('$(EXT_TARGET)'); dst=pathlib.Path('$(LEGACY_EXT_TARGET)'); shutil.copyfile(src, dst) if src.name != dst.name else None"
endif

check:
	@echo "Python: $(PYTHON)"
	@$(PYTHON) -c "import os, sys, sysconfig; print('version:', sys.version); print('platform:', sys.platform, 'os.name:', os.name); print('ext suffix:', sysconfig.get_config_var('EXT_SUFFIX'))"
	@$(PYTHON) -c "import numpy; print('numpy:', numpy.__version__); print('include:', numpy.get_include())"
	@echo "CC: $(CC)"
	@echo "target: $(EXT_TARGET)"
	@echo "supported: $(EXTENSION_SUPPORTED)"

test: extension test-exgc-sixel test-exgc-device
	$(CC) -Wall -Werror -I. tests/test_vm_infrastructure.c vm_events.c vm_console.c -o /tmp/ex716-vm-infrastructure-test
	/tmp/ex716-vm-infrastructure-test
	$(PYTHON) tests/test_fast_console.py
	$(PYTHON) tests/test_exgc_cpu24.py

exgc-sixel: $(EXGC_SIXEL_DEMO)

$(EXGC_SIXEL_DEMO): tests/exgc_sixel_test.c exgc_sixel.c exgc_sixel.h
	$(CC) -std=c99 -Wall -Werror $(BUILD_CFLAGS) -I. tests/exgc_sixel_test.c exgc_sixel.c -o $@

$(EXGC_SIXEL_UNIT): tests/test_exgc_sixel.c exgc_sixel.c exgc_sixel.h
	$(CC) -std=c99 -Wall -Werror -O2 -g -I. tests/test_exgc_sixel.c exgc_sixel.c -o $@

test-exgc-sixel: $(EXGC_SIXEL_UNIT)
	./$(EXGC_SIXEL_UNIT)

test-exgc-device:
	$(CC) -std=c99 -Wall -Werror -O2 -g -I. tests/test_exgc_device.c exgc_device.c exgc_sixel.c -o /tmp/ex716-exgc-device-test
	/tmp/ex716-exgc-device-test

benchmark-exgc-sixel: $(EXGC_SIXEL_DEMO)
	./$(EXGC_SIXEL_DEMO) --benchmark

clean:
	$(PYTHON) -c "import pathlib; [p.unlink() for p in pathlib.Path('.').glob('$(EXT_NAME)*.so') if p.is_file()]; [p.unlink() for p in pathlib.Path('.').glob('$(EXT_NAME)*.pyd') if p.is_file()]; [p.unlink() for p in pathlib.Path('.').glob('$(EXT_NAME)*.dll') if p.is_file()]; [p.unlink() for p in pathlib.Path('.').glob('*.o') if p.is_file()]; [p.unlink() for p in (pathlib.Path('$(EXGC_SIXEL_DEMO)'), pathlib.Path('$(EXGC_SIXEL_UNIT)')) if p.is_file()]"

help:
	@echo "Targets:"
	@echo "  make check      Show detected Python, NumPy, compiler, and target settings"
	@echo "  make            Build the optional $(EXT_NAME) extension for fast mode"
	@echo "  make DEBUG=0    Build optimized extension"
	@echo "  make exgc-sixel Build the standalone SIXEL pattern generator"
	@echo "  make test-exgc-sixel  Run decoder-backed standalone renderer tests"
	@echo "  make benchmark-exgc-sixel  Measure encoder-only throughput/output size"
	@echo "  make clean      Remove built extension artifacts"
