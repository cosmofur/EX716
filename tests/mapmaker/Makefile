CC ?= gcc
CFLAGS ?= -std=c89 -Wall -Wextra -Werror -pedantic
LIBRARY = ../../lib/mapmaker/mapmaker.c ../../lib/mapmaker/mapmath.c \
	../../lib/mapmaker/worldglobe.c ../../lib/mapmaker/regionalmap.c \
	../../lib/mapmaker/worldmap.c ../../lib/mapmaker/localmap.c \
	../../lib/mapmaker/worldlandscape.c
INCLUDES = -I../../lib/mapmaker -I../../lib/exgc

.PHONY: all test test-gcc test-worldgen test-worldgen-exgc test-lcc explorer survey clean worldgen-explorer

all: test-gcc

test: test-gcc test-worldgen test-worldgen-exgc

test-gcc: test_mapmaker
	./test_mapmaker

test-worldgen: test_worldgen
	./test_worldgen

test_worldgen: ../../lib/mapmaker/worldgen.c ../../lib/mapmaker/worldgen.h \
	../../lib/mapmaker/mapmath.c ../../lib/mapmaker/mapmath.h test_worldgen.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ ../../lib/mapmaker/worldgen.c \
		../../lib/mapmaker/mapmath.c test_worldgen.c

# Exercise the production ECC launcher and CPU24, without a compiler driver.
test-lcc:
	../../bin/ECC -q -DMAP_WIDTH=7 -DMAP_HEIGHT=7 -DMAPMAKER_CPU24_SMOKE=1 \
		-I ../../lib/mapmaker -o /tmp/ex716-mapmaker-ecc.asm cpu24_smoke.c
	CPUPATH=../../lib python3 ../../cpu24.py -q -f /tmp/ex716-mapmaker-ecc.asm > /tmp/ex716-mapmaker-ecc.log
	grep -qx OK /tmp/ex716-mapmaker-ecc.log
	../../bin/ECC -q -I ../../lib/exgc -o /tmp/ex716-canvas-ecc.asm exgc_canvas_cpu24.c
	CPUPATH=../../lib python3 ../../cpu24.py -q -f /tmp/ex716-canvas-ecc.asm > /tmp/ex716-canvas-ecc.log
	grep -qx OK /tmp/ex716-canvas-ecc.log
	../../bin/ECC -q -I ../../lib/mapmaker -I ../../lib/exgc -o /tmp/ex716-worldgen-ecc.asm \
		worldgen_cpu24.c worldgen_exgc.c ../../lib/exgc/exgc_canvas.c \
		../../lib/mapmaker/worldgen.c ../../lib/mapmaker/mapmath.c
	CPUPATH=../../lib python3 ../../cpu24.py -q -f /tmp/ex716-worldgen-ecc.asm > /tmp/ex716-worldgen-ecc.log
	grep -qx OK /tmp/ex716-worldgen-ecc.log

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

test_mapmaker: $(LIBRARY) ../../lib/mapmaker/mapmaker.h \
	../../lib/mapmaker/mapmath.h ../../lib/mapmaker/worldglobe.h \
	../../lib/mapmaker/regionalmap.h ../../lib/mapmaker/worldmap.h \
	../../lib/mapmaker/localmap.h test_mapmaker.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(LIBRARY) test_mapmaker.c

clean:
	rm -f test_mapmaker test_worldgen mapmaker-explorer worldgen-explorer worldglobe-survey worldgen-exgc test_worldgen_exgc

# Host WorldGen viewer using the same framebuffer and SIXEL device as CPU24.
worldgen-exgc: worldgen_exgc_viewer.c worldgen_exgc.c worldgen_exgc.h \
	worldgen_sprite_data.h ../../lib/mapmaker/worldgen.c ../../lib/mapmaker/mapmath.c \
	../../exgc_device.c ../../exgc_sixel.c ../../lib/exgc/exgc_canvas.c
	$(CC) $(filter-out -std=c89,$(CFLAGS)) -std=c99 $(INCLUDES) -I../.. -o $@ worldgen_exgc_viewer.c \
		worldgen_exgc.c ../../lib/exgc/exgc_canvas.c ../../lib/mapmaker/worldgen.c ../../lib/mapmaker/mapmath.c \
		../../exgc_device.c ../../exgc_sixel.c

worldgen-explorer: worldgen-exgc
	ln -sf worldgen-exgc worldgen-explorer

worldgen_sprite_data.h: sprites/generate_placeholder_sprites.py \
	sprites/Tiles/tile_0042.png sprites/Tiles/tile_0045.png \
	sprites/Tiles/tile_0085.png sprites/Tiles/tile_0086.png
	python3 sprites/generate_placeholder_sprites.py $@

test-worldgen-exgc: test_worldgen_exgc
	./test_worldgen_exgc

test_worldgen_exgc: test_worldgen_exgc.c worldgen_exgc.c worldgen_exgc.h \
	worldgen_sprite_data.h \
	../../lib/mapmaker/worldgen.c ../../lib/mapmaker/mapmath.c \
	../../exgc_device.c ../../exgc_sixel.c ../../lib/exgc/exgc_canvas.c
	$(CC) $(filter-out -std=c89,$(CFLAGS)) -std=c99 $(INCLUDES) -I../.. -o $@ \
		test_worldgen_exgc.c worldgen_exgc.c ../../lib/exgc/exgc_canvas.c ../../lib/mapmaker/worldgen.c \
		../../lib/mapmaker/mapmath.c ../../exgc_device.c ../../exgc_sixel.c
