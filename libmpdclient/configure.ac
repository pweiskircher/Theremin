AC_INIT(src)
AM_CONFIG_HEADER(config.h)
AM_INIT_AUTOMAKE(libmpd, 0.12.10, qball@qballcow.nl)

AC_PROG_CC
AC_LIBTOOL_WIN32_DLL
AM_PROG_LIBTOOL

AC_REPLACE_FUNCS(strndup)

EXTRA_CFLAGS=
EXTRA_LDFLAGS=
case $host in
  *-*-mingw32* | *-*-windows)
    EXTRA_CFLAGS="-mno-cygwin -mwindows -mms-bitfields -fno-strict-aliasing -DMPD_NO_GAI"
    EXTRA_LDFLAGS="-export-all-symbols -mwindows -no-undefined -lregex -lws2_32 -mms-bitfields" ;;
  *-*-cygwin*)
    EXTRA_CFLAGS="-fno-strict-aliasing"
    EXTRA_LDFLAGS="-export-all-symbols -mms-bitfields";;
esac
AC_SUBST(EXTRA_CFLAGS)
AC_SUBST(EXTRA_LDFLAGS)   

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([stdlib.h string.h unistd.h])
AC_CHECK_HEADER([regex.h], [],
                [AC_MSG_ERROR([Required header regex.h not found.])])

AC_OUTPUT([
Makefile
src/Makefile
doc/Makefile
example/Makefile
example/testcase/Makefile
libmpd.pc
src/libmpd-version.h
doc/libmpd.doxy
])
