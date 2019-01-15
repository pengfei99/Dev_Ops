# ****************************************************************************************
# *                      Copyright (c) 2011  bioMérieux S.A.                             *
# ****************************************************************************************



##############################################################################################
#nom du package :
package MummerParser::CoordsParser;

##############################################################################################
# pas d'import particulier d'autres packages :
use strict;
use List::Util qw[min];

##############################################################################################
# ce qu'on exporte automatiquement : 
use Exporter;
our @ISA  = qw (Exporter);
our @EXPORT  = qw();


##############################################################################################
##############################################################################################
#constructeur  : construit un objet a partir du fichier coords

sub new {
	my ($class, $inputfile)=@_;     #mettre en entrée le fichier contenant les résultats coords
	my $this={};
	bless ($this,$class);
	open (FIC, "<$inputfile") or die ("probleme pour ouvrir le fichier $inputfile : $!");
	my $l;
	my $i=0;
	while(defined($l=<FIC>)){
		chomp($l);
		$i++;
		if($l =~ m/^\s+(.+)\s+\|\s+(\S+)\s+(\S+)$/){
			my $seq1 = $2;
			my $seq2 = $3;
			my @info = split(/\s+\|?\s*/,$1);
#			print("@info");
			$this->{$seq1}->{$seq2}->{"S1"}   = $info[0];
			$this->{$seq1}->{$seq2}->{"E1"}   = $info[1];
			$this->{$seq1}->{$seq2}->{"S2"}   = $info[2];
			$this->{$seq1}->{$seq2}->{"E2"}   = $info[3];
			$this->{$seq1}->{$seq2}->{"LEN1"} = $info[4];
			$this->{$seq1}->{$seq2}->{"LEN2"} = $info[5];
			$this->{$seq1}->{$seq2}->{"IDY"}  = $info[6];
			$this->{$seq1}->{$seq2}->{"LENR"} = $info[7];
			$this->{$seq1}->{$seq2}->{"LENQ"} = $info[8];
			$this->{$seq1}->{$seq2}->{"COVR"} = $info[9];
			$this->{$seq1}->{$seq2}->{"COVQ"} = $info[10];	
		}
	}
#	print("\tlecture de $inputfile ok.\n $i lignes lues\n");
	close(FIC);
	return($this);
}





##############################################################################################
#fonction de recuperation de columns :

sub ColumnRecup { 
	my($this)=@_; 
	my $results;


	return($results);
}


##############################################################################################
#fonction de calcul de similarite corrigee :
## min(LEN1,LEN2)*IDY/min(LENR,LENQ)

sub CorrectedSimilarity { 
	my($this)=@_;
	my $results;
	my @names = keys(%$this);
	foreach my $seq1 (@names){
		foreach my $seq2 (@names){
			my $len1  = $this->{$seq1}->{$seq2}->{"LEN1"};
			my $len2  = $this->{$seq1}->{$seq2}->{"LEN2"};
			my $lenQ  = $this->{$seq1}->{$seq2}->{"LENQ"};
			my $lenR  = $this->{$seq1}->{$seq2}->{"LENR"};
			my $ident = $this->{$seq1}->{$seq2}->{"IDY"};	
			my $align_base = min($len1,$len2);
			my $align_max  = min ($lenQ, $lenR);
			my $new_ident;
			if($align_max != 0){$new_ident = $align_base*$ident/$align_max;}
			if($align_max == 0){$new_ident = "NA"}
			$results->{$seq1}->{$seq2} = $new_ident;
		}
	}
	
	
	
	return($results);
}

1;


=head1  ${filename}

 author ${user} Modified by $$Author $$version $$Revision$$

$$Date$$	The date the workfile was checked in
$$DateTime$$		
$$Revision$$		The revision number
$$Author$$		

=head2 DESCRIPTION

package qui permet de lire et manipuler des résultats de fichier .coords (module show-coords de mummer).  

=head2 DEPENDENCIES


=item new : 



=cut 
