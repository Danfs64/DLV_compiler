
all:
	+$(MAKE) -C src
	mv src/dlvc ./dlvc

clean:
	+$(MAKE) -C src clean
