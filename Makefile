CC          = gcc
PYTHON      ?= python3
DEBUG  = 1

# Python/NumPy include paths
PY_CFLAGS   := $(shell $(PYTHON)-config --cflags 2>/dev/null || $(PYTHON) -c "from sysconfig import get_paths; print('-I' + get_paths()['include'])")
PY_LDFLAGS  := $(shell $(PYTHON)-config --ldflags 2>/dev/null || echo "")
NUMPY_INCLUDE := $(shell $(PYTHON) -c "import numpy; print(numpy.get_include())")

# Build flags
DEBUGFLAGS  = -O0 -g
OPTFLAGS    = -O2 -DNDEBUG -Wno-cpp

ifeq ($(DEBUG),1)
  CFLAGS = $(DEBUGFLAGS) -Wall -Werror
else
  CFLAGS = $(OPTFLAGS) -Wall -Werror
endif

LDFLAGS     = $(PY_LDFLAGS)

# Targets
EXT_TARGET  = cpuCfunc.so
EXT_SRC     = speedCPU.c

.PHONY: all clean check

all: $(EXT_TARGET) $(BIN_TARGET)

# Python extension
$(EXT_TARGET): $(EXT_SRC)
	$(CC) -shared -fPIC $(EXT_SRC) \
		$(PY_CFLAGS) -I$(NUMPY_INCLUDE) \
		-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION \
		$(LDFLAGS) $(CFLAGS) -o $@

# Standalone binary
$(BIN_TARGET): $(BIN_OBJ)
	$(CC) $(BIN_OBJ) $(CFLAGS) -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

check:
	@echo "Python: $(PYTHON)"
	@$(PYTHON) -c "import sys; print('version:', sys.version)"
	@$(PYTHON) -c "import numpy; print('numpy:', numpy.__version__)"
	@$(PYTHON) -c "import numpy; print('include:', numpy.get_include())"

clean:
	rm -f $(BIN_OBJ) $(BIN_TARGET) $(EXT_TARGET)

