#! /bin/sh

## Verbose mode
test "x$VERBOSE" = xx && set -x

# Command line
../src/fqduplicate -h 2>/dev/null || exit 1
../src/fqduplicate 2>/dev/null && exit 1
../src/fqduplicate a b c 2>/dev/null && exit 1

# Default
../src/fqduplicate -t $srcdir/sample.fq >_single.ls || exit 1
grep -q ':5:3:18378:8060#' _single.ls || exit 1
grep -q ':5:2:4731:10235#' _single.ls || exit 1
../src/fqduplicate -t $srcdir/sample.fq $srcdir/sample.fq >_pair.ls || exit 1
cmp -s _single.ls _pair.ls || exit 1

# Cleanup
rm -f _*.fq _*.ls

exit 0
