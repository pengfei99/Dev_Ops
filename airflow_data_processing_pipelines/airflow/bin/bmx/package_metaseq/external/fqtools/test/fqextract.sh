#! /bin/sh

## Verbose mode
test "x$VERBOSE" = xx && set -x

## Check options
../src/fqextract -h 2>/dev/null || exit 1

## Default (no filter list)
../src/fqextract $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1

## All data (full filter list)
cat $srcdir/sample.fq | sed -n '/^@/s/^@//p' >_list.nam
../src/fqextract -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1
../src/fqextract -x -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cmp -s /dev/null _result.fq || exit 1

## No data (empty filter list)
: >_list.nam
../src/fqextract -l /dev/null $srcdir/sample.fq >_result.fq || exit 1
test -s _result.fq && exit 1
../src/fqextract -x -l /dev/null $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1

## Some data (first 10 entries)
head -n 40 $srcdir/sample.fq | sed -n '/^@/s/^@//p' >_list.nam
../src/fqextract -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cat _result.fq | sed -n '/^@/s/^@//p' >_result.nam
cmp _list.nam _result.nam || exit 1

## Default (full name)
cat $srcdir/sample.fq | sed -n '/^@/s/^@//p' >_list.nam
../src/fqextract -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1
../src/fqextract -p -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1

## List without member pair
cat $srcdir/sample.fq | sed -n '/^@/s,^@\(.*\)/[0-9],\1,p' >_list.nam
../src/fqextract -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
test -s _result.fq && exit 1
../src/fqextract -p -l _list.nam $srcdir/sample.fq >_result.fq || exit 1
cmp -s $srcdir/sample.fq _result.fq || exit 1

## Input file with both member pair
cat $srcdir/sample.fq >_sample.fq
cat $srcdir/sample.fq | sed 's,/1$,/2,' >>_sample.fq
cat $srcdir/sample.fq | sed -n '/^@/s,^@\(.*\)/[0-9],\1,p' >_list.nam
../src/fqextract -l _list.nam _sample.fq >_result.fq || exit 1
test -s _result.fq && exit 1
../src/fqextract -p -l _list.nam _sample.fq >_result.fq || exit 1
cmp -s _sample.fq _result.fq || exit 1

## Be robust against quality lines that start with '@'
cat $srcdir/sample.fq | sed -n '/^@/s/^@//p' >_list.nam
sed 's,^bbb,@@@,' $srcdir/sample.fq >_sample.fq
../src/fqextract -x -l _list.nam _sample.fq >_result.fq
cmp -s _result.fq /dev/null || exit 1

## Cleanup
rm -f _*.fq _*.nam

exit 0
