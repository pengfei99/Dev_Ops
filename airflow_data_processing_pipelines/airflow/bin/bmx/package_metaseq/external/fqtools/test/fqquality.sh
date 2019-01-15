#! /bin/sh

## Verbose mode
test "x$VERBOSE" = xx && set -x

# Command line
../src/fqquality -h 2>/dev/null || exit 1

# Default
../src/fqquality -p '' $srcdir/sample.fq || exit 1
cmp -s $srcdir/sample.fq _1.fq || exit 1

# Invalid input files
#../src/fqquality -p '' . 2>/dev/null && exit 1
#../src/fqquality -p '' $srcdir/sample.fq . 2>/dev/null && exit 1

# Cutoff value
../src/fqquality -t -p '' -q 1 $srcdir/sample.fq || exit 1
grep 'B\{1,\}$' _1.fq >/dev/null || exit 1
../src/fqquality -t -p '' -q 2 $srcdir/sample.fq || exit 1
grep 'B\{1,\}$' _1.fq >/dev/null || exit 1
../src/fqquality -t -p '' -q 3 $srcdir/sample.fq || exit 1
grep 'B\{1,\}$' _1.fq >/dev/null && exit 1

# Overall bad quality
name='HWI-EAS285_0006_"":5:4:14522:5919#TGACCA/1'
../src/fqquality -p '' -q 3 -b 50.0 $srcdir/sample.fq || exit 1
grep "^@${name}$" _1.fq >/dev/null || exit 1
../src/fqquality -p '' -q 3 -b 49.0 $srcdir/sample.fq || exit 1
grep "^@${name}$" _1.fq >/dev/null && exit 1

# Pair-end
name='HWI-EAS285_0006_"":5:4:14522:5919#TGACCA/1'
sed 's,.\{20\}\(B\{20\}\),\1\1,' $srcdir/sample.fq >_sample.fq
../src/fqquality -t -p '' -q 20 -l 20 $srcdir/sample.fq $srcdir/sample.fq || exit 1
grep "^@${name}$" _s.fq >/dev/null && exit 1
../src/fqquality -t -p '' -q 20 -l 20 $srcdir/sample.fq _sample.fq || exit 1
grep "^@${name}$" _s.fq >/dev/null || exit 1

# Cleanup
rm -f _*.fq

exit 0
