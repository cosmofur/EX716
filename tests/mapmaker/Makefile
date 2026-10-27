CC ?= gcc
CFLAGS ?= -std=c89 -Wall -Wextra -Werror -pedantic

.PHONY: all test clean

all: mapmaker-host mapmaker-validate mapmaker-ansi

mapmaker-host: mapmaker.c mapmaker.h mapmaker_host.c
	$(CC) $(CFLAGS) -o $@ mapmaker.c mapmaker_host.c

mapmaker-validate: mapmaker.c mapmaker.h mapmaker_validate.c
	$(CC) $(CFLAGS) -o $@ mapmaker.c mapmaker_validate.c

mapmaker-ansi: mapmaker.c mapmaker.h mapmaker_ansi.c
	$(CC) $(CFLAGS) -o $@ mapmaker.c mapmaker_ansi.c

test: test_mapmaker mapmaker-host mapmaker-validate mapmaker-ansi
	./test_mapmaker
	./mapmaker-host 12345 /tmp/mapmaker-test.map /tmp/mapmaker-test.bmp
	./mapmaker-validate /tmp/mapmaker-test.map
	./mapmaker-ansi /tmp/mapmaker-test.map > /tmp/mapmaker-test.ansi
	test -s /tmp/mapmaker-test.ansi

test_mapmaker: mapmaker.c mapmaker.h test_mapmaker.c
	$(CC) $(CFLAGS) -o $@ mapmaker.c test_mapmaker.c

clean:
	rm -f mapmaker-host mapmaker-validate mapmaker-ansi test_mapmaker *.map
