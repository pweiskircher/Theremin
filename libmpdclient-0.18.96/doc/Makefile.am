all: 
doc: libmpd.doxy
	doxygen $<
clean:
	rm -rf html latex

EXTRA_DIST=\
	libmpd.doxy.in\
	footer.html

.PHONY: all ldoc
