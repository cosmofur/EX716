CC = gcc
#CFLAGS = -Wall -Werror
CFLAGS = -O0 -g -Wall -Werror
# -I /usr/include/python03.10
PYTHON_INCLUDE := $(shell python3 -c "from sysconfig import get_paths as gp; print(gp()['include'])")
PYTHON_LIBS := $(shell python3-config --ldflags)
NUMPY_INCLUDE := $(shell python3 -c "import numpy; print(numpy.get_include())")



SRC = fcpu.c
OBJ = $(SRC:.c=.o)
TARGET = fcpu

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)

cpuCfunc.so: speedCPU.c
	$(CC) -shared -fPIC speedCPU.c \
	-I$(PYTHON_INCLUDE) \
	-I$(NUMPY_INCLUDE) \
	-DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION \
	$(PYTHON_LIBS) \
	-o cpuCfunc.so

#	gcc -fPIC -shared -o cpuCfunc.so speedCPU.c -I /usr/include/python3.10/ -I/home/backs1/.local/lib/python3.10/site-packages/numpy/core/include -DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION -lpython3.10 -g

