package evalTimeReader;

use strict;
use warnings;

sub read_time {
	my $file = shift;
	my $type = shift;
	
	my $sec = 0;
	
	open (INFILE, $file) or die "Can not open file $file\n";
	while(<INFILE>){
		if (/^(\d+\.\d+)user\s+\d+\.\d+system\s+.*elapsed.*CPU/ && $type eq "log"){
			$sec += $1;
		}
		# if (/^user\t(\d+)m(\d+\.\d+)s/ && $type eq "lsf"){
		if (/^\s+CPU time\s+:\s+(\d+\.*\d+)\s+sec./ && $type eq "lsf"){
			my $seconds = $1;
			# my $min = $1;
			# my $seconds = $2;
			# $sec += $min*60;
			$sec += $seconds;
		}
	}
	
	return($sec);
}

sub sec2human {
    my $secs = shift;
	
	my $days = 0;
	my $hours = 0;
	my $minutes = 0;
	
    if ( $secs >= 24*60*60) { 
		$days = int($secs/(24*60*60));
		$secs -= $days*24*60*60;
	}
	if ( $secs >= 60*60) { 
		$hours = $secs/(60*60)%24;
		$secs -= $hours*60*60;
	}
	if ( $secs >= 60) { 
		$minutes = $secs/60%60;
		$secs -= $minutes*60;
	}
	
	my $output = "";
	$output .= $days == 0 ? "" : $days."d ";
	$output .= $hours == 0 ? "" : $hours."h ";
	$output .= $minutes == 0 ? "" : $minutes."m ";
	$output .= int($secs)."s ";
	
	return $output;
    
}

sub read_mem {
	my $file = shift;
	my $type = shift;
	
	my $mem = 0;
	
	open (INFILE, $file) or die "Can not open file $file\n";
	while(<INFILE>){
		if (/\s+(\d+)maxresident\)/ && $type eq "log"){
			$mem += $1;
		}
	}
	
	return($mem);
}

1;