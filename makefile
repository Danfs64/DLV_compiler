
all:
	+$(MAKE) -C src
	mv src/a.out ./dlvc

clean:
	+$(MAKE) -C src clean
