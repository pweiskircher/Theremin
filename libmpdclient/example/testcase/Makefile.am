all:
testcase: testcase.c ../../src/*
	gcc testcase.c ../../src/*.c -I../../src -I../../ -g -o testcase -Wall -Werror
testcase-clean:
	rm testcase

EXTRA_DIST=testcase.c
