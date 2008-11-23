gcc test.c ../../src/*.c -o test -I../../ -I../../src/  -DNO_SMART_SORT
gcc test.c ../../src/*.c -o test2 -I../../ -I../../src/  
gcc test-mpdata.c ../../src/*.c -o test-mpdata -I../../ -I../../src/  -pg
echo "Withouth:"
time ./test  > /dev/null 
#output1.txt
echo -e "\n\nWith:"
time ./test2 > /dev/null 
#output2.txt
