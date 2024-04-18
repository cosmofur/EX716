CC = gcc
#CFLAGS = -Wall -Werror
CFLAGS = -O0 -g -Wall -Werror
# -I /usr/include/python03.10

SRC = fcpu.c
OBJ = $(SRC:.c=.o)
TARGET = fcpu

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)

fcpu.so: $(OBJ)
	$(CC) -c -fPIC $< -o $@  # Compile fcpu.o with -fPIC
	$(CC) -shared -o $@ $<   # Create shared library fcpu.so

cpuCfunc.so: speedCPU.c
	gcc -fPIC -shared -o cpuCfunc.so speedCPU.c -I /usr/include/python3.10/ -I/home/backs1/.local/lib/python3.10/site-packages/numpy/core/include -DNPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION -lpython3.10 -g
