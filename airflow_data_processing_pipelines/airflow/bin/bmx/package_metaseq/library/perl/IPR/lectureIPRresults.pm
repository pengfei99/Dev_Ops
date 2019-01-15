# ****************************************************************************************
# *                      Copyright (c) 2010  bioMérieux S.A.                             *
# ****************************************************************************************



##############################################################################################
#nom du package :
package IPR::lectureIPRresults;

##############################################################################################
# pas d'import particulier d'autres packages :
use strict;

#our ( @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $$VERSION ); #fait planter "use Exporter;" ?!
# PVCS information:
# $$Workfile$$
# $$Header$$
# $$Revision$$

##############################################################################################
# ce qu'on exporte automatiquement : 
use Exporter;
our @ISA  = qw (Exporter);
our @EXPORT  = qw();
#our $$VERSION = 1.0;  #?!
#use Log::Log4perl  qw(get_logger);# je sais pas à quoi ça sert


##############################################################################################
##############################################################################################
#constructeur  : 

sub new {
	my ($class, $inputfile)=@_;     #mettre en entrée le fichier contenant les résultats interpro
	my $this={};
#	$class=ref($class)||$class;
	bless ($this,$class);
	open (FIC, "<$inputfile") or die ("probleme pour ouvrir le fichier $inputfile : $!");
	my $l;
	my $i=0;
	while(defined($l=<FIC>)){
		chomp $l;
		my @t = split(/\t/,$l); #le tableau @t contient la ligne en cours de lecture du fichier $file
		if(scalar(@t) <= 2){next;} # on saute les lignes avec des retours chariots à la fin des fichiers.
		$i++;
		my $prot=$t[0];
		if (exists($this->{$prot})){
			my @tmp = @{$this->{$prot}};
			my $key = scalar(@tmp);
			#if ($t[0]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"protID"}           =$t[0]; $a++;} else {print("\tprobleme ligne $i : protID\n");}
			if ($t[1]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"crc64"}             =$t[1]; $a++;} else {print("\tprobleme ligne $i : crc64\n");}
			if ($t[2]  =~ m/\d+/){$this->{$prot}->[$key]->{"length"}                =$t[2]; $a++;} else {print("\tprobleme ligne $i : sequence length\n");}
			if ($t[3]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"DBori"}             =$t[3]; $a++;} else {print("\tprobleme ligne $i : DB origine\n");}
			if ($t[4]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"DBoriID"}           =$t[4]; $a++;} else {print("\tprobleme ligne $i : ID dans DB origine\n");}
			if ($t[5]  =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"DBdesc"}    =$t[5]; $a++;} else {print("\tprobleme ligne $i : description DB origine\n");}
			if ($t[6]  =~ m/\d+/){$this->{$prot}->[$key]->{"start"}                 =$t[6]; $a++;} else {print("\tprobleme ligne $i : start\n");}
			if ($t[7]  =~ m/\d+/){$this->{$prot}->[$key]->{"end"}                   =$t[7]; $a++;} else {print("\tprobleme ligne $i : end\n");}
			if ($t[8]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"e-value"}           =$t[8]; $a++;} else {print("\tprobleme ligne $i : e-value\n");}
			if ($t[9]  =~ m/[T\?]+/){$this->{$prot}->[$key]->{"statut"}             =$t[9]; $a++;} else {print("\tprobleme ligne $i : statut\n");}
			if ($t[10]  =~ m/[\d\w-]+/){$this->{$prot}->[$key]->{"rundate"}         =$t[10];$a++;} else {print("\tprobleme ligne $i : rundate\n");}
			if ($t[11] =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"InterProID"}        =$t[11];$a++;} else {print("\tprobleme ligne $i : ID dans InterPro\n");}
			if ($t[12] =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"IPRdesc"}   =$t[12];$a++;} else {print("\tprobleme ligne $i : dsecription dans InterPro\n");}
			if (scalar(@t) >= 14){if ($t[13] =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"GO"}        =$t[13];$a++;} else {print("\tprobleme ligne $i : GO desc\n");}}
			}
		if (!exists($this->{$prot})){
			my $key = 0;
			#if ($t[0]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"protID"}           =$t[0]; $a++;} else {print("\tprobleme ligne $i : protID\n");}
			if ($t[1]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"crc64"}             =$t[1]; $a++;} else {print("\tprobleme ligne $i : crc64\n");}
			if ($t[2]  =~ m/\d+/){$this->{$prot}->[$key]->{"length"}                =$t[2]; $a++;} else {print("\tprobleme ligne $i : sequence\n");}
			if ($t[3]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"DBori"}             =$t[3]; $a++;} else {print("\tprobleme ligne $i : DB origine\n");}
			if ($t[4]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"DBoriID"}           =$t[4]; $a++;} else {print("\tprobleme ligne $i : ID dans DB origine\n");}
			if ($t[5]  =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"DBdesc"}    =$t[5]; $a++;} else {print("\tprobleme ligne $i : description DB origine\n");}
			if ($t[6]  =~ m/\d+/){$this->{$prot}->[$key]->{"start"}                 =$t[6]; $a++;} else {print("\tprobleme ligne $i : start\n");}
			if ($t[7]  =~ m/\d+/){$this->{$prot}->[$key]->{"end"}                   =$t[7]; $a++;} else {print("\tprobleme ligne $i : end\n");}
			if ($t[8]  =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"e-value"}           =$t[8]; $a++;} else {print("\tprobleme ligne $i : e-value\n");}
			if ($t[9]  =~ m/[T\?]+/){$this->{$prot}->[$key]->{"statut"}             =$t[9]; $a++;} else {print("\tprobleme ligne $i : statut\n");}
			if ($t[10]  =~ m/[\d\w-]+/){$this->{$prot}->[$key]->{"rundate"}         =$t[10];$a++;} else {print("\tprobleme ligne $i : rundate\n");}
			if ($t[11] =~ m/[\d\w]+/){$this->{$prot}->[$key]->{"InterProID"}        =$t[11];$a++;} else {print("\tprobleme ligne $i : ID dans InterPro\n");}
			if ($t[12] =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"IPRdesc"}   =$t[12];$a++;} else {print("\tprobleme ligne $i : dsecription dans InterPro\n");}
			if (scalar(@t) >= 14){if ($t[13] =~ m/[\d\w_\:\-\.\/\s]+/){$this->{$prot}->[$key]->{"GO"}        =$t[13];$a++;} else {print("\tprobleme ligne $i : GO desc\n");}}
			}
		}
		print("\tlecture de $inputfile ok. $i lignes lues\n");
	close(FIC);
	return($this);
}





##############################################################################################
#fonction de comptage des identifiants :

sub comptageID { 
	my($this)=@_; 
	my $results;
	my $nb_prot=0;
	foreach my $prot (keys(%$this)){   #pour chaque proteines
		$nb_prot++;
		my $ref_lignes = $this->{$prot};
		my @lignes = @$ref_lignes;
		my $nl = scalar(@lignes);     # $nl correspond aux nombres de lignes de résultats interpro pour une protéine donnée
		for (my $j = 0 ; $j < $nl ; $j++){  #pour chauqe lignes de résultats de cette proteine
			if ($this->{$prot}->[$j]->{"InterProID"} ne "NULL"){							#cas ou il y a un identifiant interpro
				my $interproID = $this->{$prot}->[$j]->{"InterProID"};
				if( exists($results->{$interproID})){$results->{$interproID} += 1/$nl ;}
				if(!exists($results->{$interproID})){$results->{$interproID} = 1/$nl ;}
			}
			if ($this->{$prot}->[$j]->{"DBoriID"} eq "NULL"){							#cas ou il y a pas d'identifiant interpro correspondant
				my $dbID = $this->{$prot}->[$j]->{"DBoriID"};
				if( exists($results->{$dbID})){$results->{$dbID} += 1/$nl ;}
				if(!exists($results->{$dbID})){$results->{$dbID} =  1/$nl ;}
			}
			
		}
	}
	return($results);
}


##############################################################################################
#fonction de comptage des identifiants :

sub recupIDs { 
	my($this)=@_; 
	my $results;
	my $nb_prot=0;
	foreach my $prot (keys(%$this)){   #pour chaque proteines
		#print "$prot\n";
		$nb_prot++;
		my $ref_lignes = $this->{$prot};
		my @lignes = @$ref_lignes;
		my $nl = scalar(@lignes);     # $nl correspond aux nombres de lignes de résultats interpro pour une protéine donnée
		for (my $j = 0 ; $j < $nl ; $j++){  #pour chauqe lignes de résultats de cette proteine
			if ($this->{$prot}->[$j]->{"InterProID"} ne "NULL"){							#cas ou il y a un identifiant interpro
				my $interproID   = $this->{$prot}->[$j]->{"InterProID"};					## on recupert l'ID interproscan
				my $interproDesc = $this->{$prot}->[$j]->{"IPRdesc"};
				#if( exists($results->{$prot}->{$interproID}){}# && $results->{$prot}->{$interproID} ne $interproDesc)){$results->{$prot}->{$interproID} .= ",".$interproDesc ;}
				if(!exists($results->{$prot}->{$interproID})){$results->{$prot}->{$interproID} = $interproDesc ;}
			}
			if ($this->{$prot}->[$j]->{"InterProID"} eq "NULL" && $this->{$prot}->[$j]->{"DBoriID"} ne "NULL"){					#cas ou il y a pas d'identifiant interpro correspondant
				my $dbID = $this->{$prot}->[$j]->{"DBori"}."_".$this->{$prot}->[$j]->{"DBoriID"};								## on recupert DBori_DBoriID
				my $dbDesc = $this->{$prot}->[$j]->{"DBdesc"};
				#if( exists($results->{$prot}->{$dbID}){}# && $results->{$prot}->{$dbID} ne $dbDesc)){$results->{$prot}->{$dbID} .= ",".$dbDesc ;}
				if(!exists($results->{$prot}->{$dbID})){$results->{$prot}->{$dbID} = $dbDesc ;}
			}
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

package qui permet de lire et manipuler des résultats d'InterProScan.  

=head2 DEPENDENCIES


=head2 METHODS
=item new : 


=item TrypsinDigestion : 


=item autre type : 


=cut #resuming commentation

