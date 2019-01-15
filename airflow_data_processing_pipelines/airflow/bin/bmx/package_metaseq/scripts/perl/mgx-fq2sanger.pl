#! /usr/bin/env perl
####################################################################################################################
# Programme FastqToSanger.pl Ecrit par G.guigon, Fev 2012
# Programme qui prend en entrée le fichier fastq à convertir et le fichier de sortie
# Si le fichier de sortie n'est pas précise, seul la verification est faite
# ex :perl FastqToSanger.pl -i Lyssa1.fq -o Lyssa1_sanger.fq
####################################################################################################################
use strict;
use warnings;
use List::Util qw(sum min max);
use Getopt::Long;
use File::Basename;

# Parameter variables
my $file;
my $helpAsked;
my $outFile;
my $subVal;

my $seqFormat = "a";

GetOptions(
			"i=s" => \$file,
			"h|help" => \$helpAsked,
			"o|outputFolder=s" => \$outFile,
			"v|fastqVariant=s" => \$seqFormat,
		  );
if(defined($helpAsked)) {
	prtUsage();
	exit;
}
if(!defined($file)) {
	prtError("No input files are provided");
}

my ($fileName,$filePath,$ext) = fileparse($file, qr/\.[^.]*/);

print "Checking FASTQ format: File $file...\n";
$seqFormat = checkFastQFormat($file, 1);

if($seqFormat == 1) {
	$subVal = 33;
	print "Input FASTQ file format: Sanger\n";
}
elsif($seqFormat == 2) {
	$subVal = 64;
	print "Input FASTQ file format: Solexa\n";
}
elsif($seqFormat == 3) {
	$subVal = 64;
	print "Input FASTQ file format: Illumina 1.3+\n";
}
elsif($seqFormat == 4) {
	$subVal = 64;
	print "Input FASTQ file format: Illumina 1.5+\n";
}
elsif($seqFormat == 5) {
	$subVal = 64;
	print "Input FASTQ file format: Illumina 1.7+\n";
}
elsif($seqFormat == 6) {
	$subVal = 33;
	print "Input FASTQ file format: Illumina 1.8+\n";
}

if (defined $outFile){
	open(I, "<$file") or die "Can not open file: $file\n";
	my $count = 0;
	my $cpt = 0;
	if ($seqFormat ==2 || $seqFormat == 3 || $seqFormat == 4 || $seqFormat == 5){
		open(FQ, ">$outFile") or die "Can not open file: $outFile\n";
		while(my $line = <I>) {
			$line =~ s/\r//g;
			$line =~ s/\n//g;
			if ($count++ % 4 == 3) { 
				$line =~ tr/\x40-\xff\x00-\x3f/\x21-\xe0\x21/; 
				$cpt++;
				}
			#if ($line =~ /^\+/) { $line =~ s/^\+.*/\+/; } ne passe pas dans CLC
			print FQ "$line\n";
		}
		print "Output FASTQ Sanger file $outFile : $cpt sequences\n";
		close (FQ);
	}
	else{exit;}
	close (I);
	
}

sub checkFastQFormat {# Takes FASTQ file as an input and if the format is incorrect it will print error and exit, otherwise it will return the number of lines in the file.
	my $file = $_[0];
	my $isVariantIdntfcntOn = $_[1];
	my $lines = 0;
	open(F, "<$file") or die "Can not open file $file\n";
	my $counter = 0;
	my $minVal = 1000;
	my $maxVal = 0;
	while(my $line = <F>) {
		$line =~ s/\r//g;
		$line =~ s/\n//g;
		$lines++;
		$counter++;
		
		next if($line =~ /^\n$/);
		if($counter == 1 && $line !~ /^\@/) {
			print("Invalid FASTQ file format.\n\t\tFile: $file");
			exit;
		}
		if($counter == 3 && $line !~ /^\+/) {
			print("Invalid FASTQ file format.\n\t\tFile: $file");
			exit;
		}
		if($counter == 4 && $lines < 40000) {
			chomp $line;
			my @ASCII = unpack("C*", $line);
			$minVal = min(min(@ASCII), $minVal);
			$maxVal = max(max(@ASCII), $maxVal);			
		}
		if($counter == 4) {
			$counter = 0;
		}
	}
	close(F);
	my $tseqFormat = 0;
	
	if($minVal >= 33 && $minVal <= 73 && $maxVal >= 33 && $maxVal <= 73) {
		$tseqFormat = 1;
	}
	if($minVal >= 33 && $minVal <= 74 && $maxVal >= 33 && $maxVal <= 74) {
		$tseqFormat = 6;			# Illumina 1.8+
	}
	if($minVal >= 66 && $minVal <= 105 && $maxVal >= 66 && $maxVal <= 105) {
		$tseqFormat = 5;			# Illumina 1.7+
	}
	if($minVal >= 66 && $minVal <= 104 && $maxVal >= 66 && $maxVal <= 104) {
		$tseqFormat = 4;			# Illumina 1.5+
	}
	if($minVal >= 64 && $minVal <= 104 && $maxVal >= 64 && $maxVal <= 104) {
		$tseqFormat = 3;			# Illumina 1.3+
	}
	if($minVal >= 59 && $minVal <= 104 && $maxVal >= 59 && $maxVal <= 104) {
		$tseqFormat = 2;			# Solexa
	}
	if($isVariantIdntfcntOn) {
		$seqFormat = $tseqFormat;
	}
	else {
		if($tseqFormat != $seqFormat) {
			print STDERR "Warning: It seems the specified variant of FASTQ doesn't match the quality values in input FASTQ files.\n";
		}
	}
 
	return $tseqFormat;
}


sub prtHelp {
	print "\n$0 options:\n\n";
	print "### Input reads (FASTQ) (Required)\n";
	print "  -i <Illumina FASTQ read file>\n";
	print "    Read file in Illumina FASTQ format\n";
	print "\n";
	print "### Other options [Optional]\n";
	print "  -h | -help\n";
	print "    Prints this help\n";
	print "  -o | -outputFile <Output file name>\n";
	print "    Output will be stored in the given file\n";
	print "    Format CASAVA 1.3 to 1.7 quality scores to Sanger quality scores \n";
	print "    If output file is not precised, check and return the quality score type but no output file will be generated\n";
	print "  -v | -fastqVariant <FASTQ variant>\n";
	print "    FASTQ variants:\n";
	print "      1 = Sanger (Phred+33, 33 to 73)\n";
	print "      2 = Solexa (Phred+64, 59 to 104)\n";
	print "      3 = Illumina (1.3+) (Phred+64, 64 to 104)\n";
	print "      4 = Illumina (1.5+) (Phred+64, 66 to 104)\n";
	print "      5 = Illumina (1.7+) (Phred+64, 66 to 105)\n";
	print "      6 = Illumina (1.8+) (Phred+33, 33 to 74)\n";
	print "      A = Automatic detection of FASTQ variant\n";
	print "    default: \"A\"\n";
	print "\n";
}

sub prtError {
	my $msg = $_[0];
	print STDERR "+======================================================================+\n";
	printf STDERR "|%-70s|\n", "  Error:";
	printf STDERR "|%-70s|\n", "       $msg";
	print STDERR "+======================================================================+\n";
	prtUsage();
	exit;
}

sub prtUsage {
	print "\nUsage: perl $0 <options>\n";
	prtHelp();
}


