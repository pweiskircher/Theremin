INCLUDES = 				\
	-I.				\
	-I$(top_srcdir)			\
	@EXTRA_CFLAGS@ -Werror -Wall -Wmissing-declarations 


lib_LTLIBRARIES = libmpd.la

libmpd_la_SOURCES =			\
		libmpd.c		\
		libmpd-player.c		\
		libmpd-status.c		\
		libmpd-playlist.c	\
		libmpdclient.c		\
		libmpd-strfsong.c	\
		libmpd-database.c	\
		debug_printf.c		\
		libmpd-version.h.in

libmpdinclude_HEADERS = 		\
		libmpd.h		\
		libmpd-player.h		\
		libmpd-status.h		\
		libmpd-playlist.h	\
		libmpd-database.h	\
		libmpd-internal.h	\
		libmpdclient.h		\
		libmpd-strfsong.h	\
		libmpd-version.h	\
		debug_printf.h

EXTRA_DIST = \
	libmpd-version.h.in

libmpd_la_LIBADD = 
libmpd_la_LDFLAGS = @EXTRA_LDFLAGS@ 
libmpdincludedir= $(includedir)/libmpd/
