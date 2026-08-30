bin/menubar_watch: menubar_watch.c | bin
	clang -std=c99 -O3 -Wall -framework CoreGraphics -framework CoreFoundation $< -o $@

bin:
	mkdir bin

clean:
	rm -rf bin
