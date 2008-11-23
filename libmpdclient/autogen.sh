echo "running aclocal"
aclocal
echo "running autoheader"
autoheader
echo "running libtoolize"
libtoolize --force
echo "running automake"
automake -a -c
echo "running autoconf"
autoconf
echo "running configure"
./configure "$@"
