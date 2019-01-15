#! /usr/bin/env perl

# **************************************************************************
# *           Copyright (c) 2011  bioMérieux S.A.
# **************************************************************************

##########################################################################################
#chargement des packages :

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;
use Bio::Seq;

##########################################################################################
# options en entrées :

## matrice non consolidee (.gz ou non) :
my $matrix_f;

## fichier decrivant la taxonomie de reference utilisee (exemple : NCBI nodes.dmp file)
my $nodes_f;

## fichier des noms des taxids (exemple : NCBI names.dmp file)
my $names_f;

## definir le nom du fichier de sortie (par default list_taxon_level.txt)
my $output_f = ".\/matrix_consolidated.txt";

#my $output_d = ".\/";

GetOptions ('matrix|m=s'=>\$matrix_f, 'names|n=s'=>\$names_f ,
			'nodes|taxo=s'=>\$nodes_f , 'output|o=s'=>\$output_f);


print STDOUT "
###############################\n# DEBUT matrixconsolidated.pl #\n###############################

	Script options :
	################

		'matrix file' = $matrix_f
		'nodes'       = $nodes_f
		'output       = $output_f

";

print STDOUT "\t# Read files and extract informations\n";

##########################################################################################
# Read the matrix file : on recupere le nombre de run que contient la matrice et la liste des taxid (ranges dans une hash)
##########################################################################################

print "\t\t## Read matrix file... ";
open(MAT, "<$matrix_f") or die ("ATTENTION : n'arrive par a ouvrir le document $matrix_f : $!\n");

my $titre;
my $l;
my $listid;
my $runnb;

while(defined($l=<MAT>)){

	chomp($l);
	my @t = split(/\t/,$l);

	if($t[0] eq "taxid"){
		$runnb = scalar(@t) - 3;
		$titre=$l;
	} else{
		$listid->{$t[0]} = 0;
	}

}
close(MAT);
print "done.\n";

##########################################################################################
# Read nodes.dump (or 3 columnes) file
##########################################################################################

print "\t\t## Read taxonomy file...\n";

my $node_def;
my $err = 0;
undef($l);
my @length    = keys(%$listid);
my $tot       = scalar keys(%$listid);
my $relecture = 10;

# Tant qu'il y a des clés dans le hash
while($tot > 0){ # ici on continue temps qu'on est pas remonte a la racine pour tous les id de la liste d'origine

	open(NODES, "<$nodes_f") or die ("ATTENTION : n'arrive par a ouvrir le document $nodes_f : $!\n");

	# On traite toutes les lignes du fichier nodes.dmp
	while( defined( $l = <NODES> ) ){

		chomp($l);

		# Si la ligne du fichier nodes.dmp traitée peut être parsé grace à la regex suivante
		if( $l =~ m/^(\d+)\t\|?\t?(\d+)\t\|?\t?([\w ]+|no rank)\t+.*$/ ){

			# On récupère les 3 premiers champs de chaque ligne
			my $parent = $2;
			my $level  = $3;
			my $curent = $1;

			# Si l'ID de la ligne traitée est dans notre matrice
			if( exists( $listid->{$curent} ) ){

				# on récupère son ID parent et son rang taxonomique
				$node_def->{$curent}->{"parent"} = $parent;
				$node_def->{$curent}->{"level"}  = $level;

				# $node_def->{$curent}->{"nb_seq"} = 0;
				# if($parent == 1578){print "taxid $curent have $parent as parent\n";}

				# Si le parent est différent = si le taxid traité n'est pas la racine
				if ($parent != $curent){ #si le curent n'est pas la racine --> racine : 1 | 1

					# On supprime la clé du hash
					delete( $listid->{$curent} );
					$listid->{$parent} = 0; #on recherchera ce parent au prochain passage

				} else {
					# On supprime la clé correspondant à la racine du hash
					delete( $listid->{$curent} );
				}

			}

		} else {
			$err++;
			print("Problème avec la ligne suivante du fichier nodes.dmp : ".$l."\n");
		}
	}

	close(NODES);

	# On récupére les clés restantes dans un tableau
	@length = keys (%$listid);

	# On récupére le nombre de clés restantes
	my $nbtaxid = scalar keys (%$listid);

	if( $nbtaxid == $tot ){
		$relecture--;
		print("");
	} else {
		$relecture = 10;
	}

	# On récupére le nombre de clés restantes
	$tot = scalar keys (%$listid); # a la fin il ne reste plus d'element dans la hash

	print("\t\t\tnombre de taxID restants : ".$nbtaxid." (".$relecture.")\n");

	if( $relecture == 0 ){
		$tot = 0;
	}

}

$err += scalar keys (%$listid);

if( $err > 0 ){
	if ( $err == 1 ){print("\n\t\t\t$err ligne n'a pas ete reconnue\n");}
	if ( $err > 1 ){print("\n\t\t\t$err lignes n'ont pas ete reconnues\n");}
}

if( @length != 0 ){

	my $err_log = "./problems_taxonlist.txt";
	open(ERR, ">$err_log") or die ("ATTENTION : n'arrive par a ouvrir le document $err_log : $!\n");

	foreach my $errs (@length) {
		print(ERR "$errs\n");
	}

}

print "\t\tdone\n\n";

##########################################################################################
# pour chaque run on parcourt de nouveau la matrice l'origine pour compter le nombre de sequence en chaque noeud
##########################################################################################

#my $count;
my $hashnames;

for (my $i=0 ; $i < $runnb ; $i++){
	my $num_run = $i+1;
	print "\t# Run $num_run\n";
	print "\t# Count sequences for each taxon... ";
	open(MAT, "<$matrix_f") or die ("ATTENTION : n'arrive par a ouvrir le document $matrix_f : $!\n");
	undef($l);
	# my @list_id;
	my $current;
	my $parent;

	while(defined($l=<MAT>)){

		# pour chaque sequence on ajoute +1 à toute la hierarchie
		chomp($l);

		if($l =~ m/^\d+/){

			my @tableau = split(/\t/,$l);
			# my $long = scalar(@tableau);
			# if($long != 4){print "WARNING : tableau length = $long\n";}
			# push(@list_id, $tableau[0]);

			if(exists($node_def->{$tableau[0]})){

				$node_def->{$tableau[0]}->{$i}->{"nb_seq"} += $tableau[$i+3];
				$node_def->{$tableau[0]}->{"taxname"} = $tableau[2];
				$node_def->{$tableau[0]}->{"rank"} = $tableau[1];
				$current = $tableau[0];
				$parent = $node_def->{$tableau[0]}->{"parent"};
				# print "Y".$current."\t".$parent."\t".$tableau[2]."\t".$tableau[$i+3]."\n";
				# if($current == 1578){print "seq nb genus 1578 to add : $tableau[$i+3] \n";$count += $tableau[$i+3];}

				while($current ne $parent){ # tant qu'on est pas a la racine

					$current = $parent;
					$parent = $node_def->{$parent}->{"parent"};
					$node_def->{$current}->{$i}->{"nb_seq"} += $tableau[$i+3];
					$hashnames->{$current} = 0;
					# if($current == 1578){print "seq nb genus 1578 to add : $tableau[$i+3]\n";$count += $tableau[$i+3];}
					# print "Z".$current."\t".$parent."\t".$tableau[2]."\t".$tableau[$i+3]."\n";

				}

			} else {
				print("!!! ATTENTION : le tax_id $tableau[0] n'est pas decrit dans le fichier nodes !!!\n")
			}

		}
	}

	close(MAT);
	print "done\n\n";

}

#print "\ncount 1578 = $count\n\n";

##########################################################################################
# ouvrir names.dmp : on recupert ici le nom des taxid
##########################################################################################

open(NAMES, "<$names_f") or die ("ATTENTION : n'arrive par a ouvrir le document $names_f : $!\n");

undef($l);

while( defined( $l = <NAMES> ) ){

	chomp $l;
	my @tabnames = split(/\t\|\t/,$l);
	# print "$tabnames[3]\n";

	if($tabnames[3] =~ m/^scientific name/){
		my $taxid=$tabnames[0];
		my $name = $tabnames[1];
		if(exists($hashnames->{$taxid})){$node_def->{$taxid}->{"taxname"} = $name;}
	}

}

close(NAMES);
#exit;

##########################################################################################
# Format results : on sort les resultats consolides sous le meme format que le fichier en input
# format : taxid	rank	taxname	nb_run1	nb_run2...
##########################################################################################

open(OUT, ">$output_f") or die ("ATTENTION : n'arrive par a ouvrir le document $output_f : $!\n");

print(OUT "$titre\n");
#my $j=0;

foreach my $keys (keys(%$node_def)){

	# print "$j\n";
	# $j++;
	my $taxid = $keys;
	my $rank = $node_def->{$keys}->{"level"};
	my $taxname = $node_def->{$keys}->{"taxname"};
	# print "$taxid\t$rank\t$taxname\n";
	my $ligne = $taxid."\t".$rank."\t".$taxname;

	for (my $i = 0 ; $i < $runnb ; $i++){
		my $nb = $node_def->{$keys}->{$i}->{"nb_seq"};
		$ligne .= "\t".$nb;
	}

	print(OUT "$ligne\n");

}

close(OUT);

print STDOUT "#############################\n# FIN matrixconsolidated.pl #\n#############################\n";

##########################################################################################

=head1 ${filename}

author N Mugnier Modified by $$Author $$version  $$Revision$$

=head2 SYNOPSIS

this script performe the matrix consolidation according to the ncbi taxonomy.
for each taxonomic level return the sum of each number of sequences found in its descendants

=head2 DESCRIPTION

input file :
not consolidated matrix with following columns:
	- taxid = ncbi tax id
	- rank = ncbi taxonomic level
	- taxname = scientific name
	- following columns = number of sequences in each run

output :
same file with consolidated number of sequences

options :
	-matrix|m = not consolidated matrix (only number of sequences by each leave)
	-names|n = ncbi names.dmp
	-nodes = fichier decrivant la taxonomie = ncbi nodes.dmp (pour chaque noeud : son parent et son niveau)
	-o = outputfile

=head2 DEPENDENCIES

module perl utilisés :
Getopt::Long
use Bio::SeqIO;
use Bio::Seq;
use Bio::Tools::IUPAC;

=head2 PRINCIPE

=head2 METHODS

=cut
