SUBDIRS = src doc example

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libmpd.pc

EXTRA_DIST = libmpd.pc.in

doc:
	make -C doc PACKAGE=$(PACKAGE)

.PHONY: doc
