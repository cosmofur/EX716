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
