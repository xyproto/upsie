.PHONY: clean all aarch64 build-run build-aarch64 distclean

all: upsie

upsie: main.zig
	zig build-exe main.zig -O ReleaseFast --name upsie -lc

small: main.zig
	zig build-exe main.zig -O ReleaseSmall --name upsie -lc

aarch64: main.zig
	zig build-exe main.zig -O ReleaseFast --name upsie-aarch64 -target aarch64-linux -lc

build-run:
	zig build run

build-aarch64:
	zig build aarch64

clean:
	rm -rf upsie upsie-aarch64 zig-out

distclean: clean
	rm -rf .zig-cache
