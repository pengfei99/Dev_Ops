#! @XPERLX@

use strict;
use warnings;

use File::Basename;
use Getopt::Std;

# Inits
my $prg = File::Basename::basename($0);
my %opt = ();
my $dir = '@pkglibexecdir@';
my $tmp = "fqduplicate.$$";

# Command line
if (not Getopt::Std::getopts('ht', \%opt)) { usage(); exit 1; }
if (exists $opt{'h'}) { usage(); exit 0; }
if (scalar @ARGV < 1 or scalar @ARGV > 2) { usage(); exit 1; }
if (exists $opt{'t'}) { $dir = File::Basename::dirname($0); }

# Check duplicate entries
my $prv = "";
open IN, "$dir/fqduplicate2 @ARGV | sort -k 1,1 -k 2,2nr |";
while (<IN>) {
  my ($key, $val, $nam) = split;
  if ($prv eq $key) { printf "%s\n", $nam; }
  $prv = $key; }
close IN;

exit 0;


## Usage display
sub usage {
  printf STDERR "usage: %s [-h] <file> [<file>]\n", $prg; }
