CC = gcc
#CFLAGS = -Wall -Werror
CFLAGS = -O0 -g -Wall -Werror

SRC = fcpu.c
OBJ = $(SRC:.c=.o)
TARGET = fcpu

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)
