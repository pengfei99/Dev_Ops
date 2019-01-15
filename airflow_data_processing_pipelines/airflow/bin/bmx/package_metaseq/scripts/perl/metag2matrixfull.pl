#! /usr/bin/perl

use strict;
use IO::File;


my %INPUT_HASH;
my %INPUT_HASH_TAXID;
my %INPUT_HASH_SAMPLE;
print STDERR " Load cat metagenomic results of samples";
while(<STDIN>)
{
	chomp;    
	my @t=split(/\t/);
	push(@{$INPUT_HASH{$t[1]}{$t[0]}}, $t[4]);
	$INPUT_HASH_TAXID{$t[1]} = $t[2]."\t".$t[3];
	$INPUT_HASH_SAMPLE{$t[0]} = "";
}
print STDERR " [ OK ]\n";


print STDOUT "taxid\trank\ttaxname";
for my $i (keys(%INPUT_HASH_SAMPLE))
{
	print STDOUT "\t",$i;
}
print STDOUT "\n";


foreach my $taxid (keys(%INPUT_HASH_TAXID))
{
	print STDOUT $taxid, "\t", $INPUT_HASH_TAXID{$taxid};
	for my $i (keys(%INPUT_HASH_SAMPLE))
	{
		if (exists $INPUT_HASH{$taxid}{$i})
		{
#			print STDOUT "\t",$i,"\t",$INPUT_HASH{$taxid}{$i}[0];
			print STDOUT "\t",$INPUT_HASH{$taxid}{$i}[0];
		}else
		{
#			print STDOUT "\t",$i,"\t0",$INPUT_HASH{$taxid}{$i}[0];
			print STDOUT "\t0",$INPUT_HASH{$taxid}{$i}[0];
		}
	}
	print STDOUT "\n";
}
   
exit(0);
