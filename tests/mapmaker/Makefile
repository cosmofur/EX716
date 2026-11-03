CC ?= gcc
CFLAGS ?= -std=c89 -Wall -Wextra -Werror -pedantic
LIBRARY = ../../lib/mapmaker/mapmaker.c ../../lib/mapmaker/mapmath.c \
	../../lib/mapmaker/worldglobe.c ../../lib/mapmaker/regionalmap.c \
	../../lib/mapmaker/worldmap.c ../../lib/mapmaker/localmap.c \
	../../lib/mapmaker/worldlandscape.c
INCLUDES = -I../../lib/mapmaker

.PHONY: all test test-gcc test-lcc explorer clean

all: test-gcc

test: test-gcc

test-gcc: test_mapmaker
	./test_mapmaker

test-lcc:
	python3 cpu24_smoke.py

explorer: mapmaker-explorer

mapmaker-explorer: $(LIBRARY) ../../lib/mapmaker/mapmaker.h \
	../../lib/mapmaker/worldglobe.h ../../lib/mapmaker/regionalmap.h \
	../../lib/mapmaker/localmap.h mapmaker_explorer.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(LIBRARY) mapmaker_explorer.c

test_mapmaker: $(LIBRARY) ../../lib/mapmaker/mapmaker.h \
	../../lib/mapmaker/mapmath.h ../../lib/mapmaker/worldglobe.h \
	../../lib/mapmaker/regionalmap.h ../../lib/mapmaker/worldmap.h \
	../../lib/mapmaker/localmap.h test_mapmaker.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(LIBRARY) test_mapmaker.c

clean:
	rm -f test_mapmaker mapmaker-explorer
