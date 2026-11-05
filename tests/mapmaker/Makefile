CC ?= gcc
CFLAGS ?= -std=c89 -Wall -Wextra -Werror -pedantic
LIBRARY = ../../lib/mapmaker/mapmaker.c ../../lib/mapmaker/mapmath.c \
	../../lib/mapmaker/worldglobe.c ../../lib/mapmaker/regionalmap.c \
	../../lib/mapmaker/worldmap.c ../../lib/mapmaker/localmap.c \
	../../lib/mapmaker/worldlandscape.c
INCLUDES = -I../../lib/mapmaker

.PHONY: all test test-gcc test-worldgen test-lcc explorer survey clean

all: test-gcc

test: test-gcc test-worldgen

test-gcc: test_mapmaker
	./test_mapmaker

test-worldgen: test_worldgen
	./test_worldgen

test_worldgen: ../../lib/mapmaker/worldgen.c ../../lib/mapmaker/worldgen.h \
	../../lib/mapmaker/mapmath.c ../../lib/mapmaker/mapmath.h test_worldgen.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ ../../lib/mapmaker/worldgen.c \
		../../lib/mapmaker/mapmath.c test_worldgen.c

test-lcc:
	python3 cpu24_smoke.py

explorer: mapmaker-explorer

survey: worldglobe-survey

worldglobe-survey: ../../lib/mapmaker/worldglobe.c ../../lib/mapmaker/worldglobe.h \
	../../lib/mapmaker/worldlandscape.c ../../lib/mapmaker/worldlandscape.h worldglobe_survey.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ ../../lib/mapmaker/worldglobe.c \
	../../lib/mapmaker/worldlandscape.c ../../lib/mapmaker/mapmath.c worldglobe_survey.c

mapmaker-explorer: $(LIBRARY) ../../lib/mapmaker/mapmaker.h \
	../../lib/mapmaker/worldglobe.h ../../lib/mapmaker/regionalmap.h \
	../../lib/mapmaker/localmap.h mapmaker_explorer.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(LIBRARY) mapmaker_explorer.c

worldgen-explorer: ../../lib/mapmaker/worldgen.c ../../lib/mapmaker/worldgen.h \
	../../lib/mapmaker/mapmath.c ../../lib/mapmaker/mapmath.h worldgen_explorer.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ ../../lib/mapmaker/worldgen.c \
		../../lib/mapmaker/mapmath.c worldgen_explorer.c

test_mapmaker: $(LIBRARY) ../../lib/mapmaker/mapmaker.h \
	../../lib/mapmaker/mapmath.h ../../lib/mapmaker/worldglobe.h \
	../../lib/mapmaker/regionalmap.h ../../lib/mapmaker/worldmap.h \
	../../lib/mapmaker/localmap.h test_mapmaker.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(LIBRARY) test_mapmaker.c

clean:
	rm -f test_mapmaker test_worldgen mapmaker-explorer worldgen-explorer worldglobe-survey
