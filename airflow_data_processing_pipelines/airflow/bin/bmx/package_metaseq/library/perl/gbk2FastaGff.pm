package gbk2FastaGff;


# Convert GenBank file into Fasta files (.fna, .ffn, .frn, .faa) and GFF file.

use strict;
use warnings;

use Bio::SeqIO;
use Bio::Tools::GFF;
use Bio::LocationI;

use bioseq_extractGbkAnnotation;

sub main {	

	my ($genbank_file,$fna,$ffn,$frn,$faa,$gff,$output_dir) = @_;
	$output_dir = '' if (!defined $output_dir);
	
	print "GenBank file conversions\n";
	print "\tgenbank file : $genbank_file\n";
	
	if (-e $genbank_file) {
			print "\t...File Exists\n";

		# Open and read the GenBank file
		my $Genbank_file = Bio::SeqIO->new(-file => $genbank_file, -format => 'genbank');
		
		# Creation of fasta files and gff file
			print "\t...Input streams created\n";

		my $ffn_fasta_file = create_fasta_file($genbank_file,".ffn",$output_dir) if ($ffn == 1);
		my $frn_fasta_file = create_fasta_file($genbank_file,".frn",$output_dir) if ($frn == 1);
		my $faa_fasta_file = create_fasta_file($genbank_file,".faa",$output_dir) if ($faa == 1);
		my $fna_fasta_file = create_fasta_file($genbank_file,".fna",$output_dir) if ($fna == 1);
		my $GFF_IO = create_gff_file($genbank_file,".gff",$output_dir) if ($gff == 1);
			print "\t...Output streams created\n";

		# Get the taxids table (one taxid per sequence, from the first source feature of each sequence)
		my $alltaxid = bioseq_extractGbkAnnotation::extract_taxid_table_in_genbank_file($genbank_file);
		my @taxids = @$alltaxid;
		my $seqCount = 0;
		print "\tTaxid : ".$taxids[0]."\n";

		while ( my $sequence = $Genbank_file->next_seq() ) {
		
		my %sequence_info;
		if ($fna == 1 || $ffn == 1 || $faa == 1) {
			$sequence_info{"accession"} = $sequence->accession();
			$sequence_info{"version"} = $sequence->version();
			$sequence_info{"GI"} = $sequence->primary_id();
			$sequence_info{"description"} = $sequence->desc();
			$sequence_info{"taxid"} = "";
			$sequence_info{"taxid"} = $taxids[$seqCount] if (defined $taxids[$seqCount]);
		}
		$seqCount++;
		print "Seq Info : ".$sequence_info{"taxid"}."\n";

		# fna fasta file
		if ($fna == 1) {
			print "\t\tfna fasta file creation\n";
			#my $new_ID = $sequence_info{"accession"}." "."gi|".$sequence_info{"GI"}."|ref|".$sequence_info{"accession"}.".".$sequence_info{"version"}."|"." ".$sequence->desc();
			my $new_ID = $sequence_info{"accession"}." ".$sequence_info{"description"}." ".$sequence_info{"taxid"};
			write_id_and_seq($fna_fasta_file,$new_ID,$sequence->seq());
		}
		
		
			
		# Features of genbank file
		if ($ffn == 1 || $frn == 1 || $faa == 1 || $gff == 1) {
			print "\t\tffn, frn and faa fasta files and gff file creation\n";		
			my $organism;
			my $feat_object;
			
			my $pseudo = 0;
			my @pseudo_Seq_objects_ffn;
			my @pseudo_Seq_objects_faa;
			
			foreach $feat_object($sequence->all_SeqFeatures()) {
				my $primary_tag = $feat_object->primary_tag();
				
				# GFF
				$GFF_IO->write_feature($feat_object) if ($gff == 1);
			
				if ($primary_tag eq "source") {
					# ffn and faa fasta files
					if ($ffn == 1 || $faa == 1) {
						$organism = extract_value($feat_object,"organism",$sequence);
					}
				} else {
					if ($primary_tag eq "CDS") {
						
						if ($feat_object->has_tag("pseudo")) {
							$pseudo = 1;
							my ($ID_gene,$gene_seq) = to_ffn($feat_object,\%sequence_info,$organism,$sequence,1);
							my $seq_object_ffn = Bio::Seq->new(-id => $ID_gene, -seq => $gene_seq);
							if ($ffn == 1) {
								push(@pseudo_Seq_objects_ffn,$seq_object_ffn);
							}
							if ($faa == 1) {
								my ($ID_protein,$protein_seq) = to_faa($feat_object,\%sequence_info,$organism,$sequence,1);						
								my $seq_object_prot = $seq_object_ffn->translate();
								my $prot_seq = $seq_object_prot->seq();
								
								my $seq_object_faa = Bio::Seq->new(-id => $ID_protein, -seq => $prot_seq);
								
								push(@pseudo_Seq_objects_faa,$seq_object_faa);
							}
						} else {
							if ($ffn == 1) {
								my ($ID_gene,$gene_seq) = to_ffn($feat_object,\%sequence_info,$organism,$sequence,0);
								write_id_and_seq($ffn_fasta_file,$ID_gene,$gene_seq);
							}
							if ($faa == 1) {
								my ($ID_protein,$protein_seq) = to_faa($feat_object,\%sequence_info,$organism,$sequence,0);
								write_id_and_seq($faa_fasta_file,$ID_protein,$protein_seq);
							}
						}
						
						
					} else {
						if ($primary_tag eq "tRNA" || $primary_tag eq "rRNA" || $primary_tag eq "misc_RNA") {
							if ($frn == 1) {
								my ($ID_RNA,$RNA_seq) = to_frn($feat_object,\%sequence_info,$primary_tag,$sequence);
								write_id_and_seq($frn_fasta_file,$ID_RNA,$RNA_seq);
							}
						}
					}
				}
			}
			
			if ($pseudo == 1) {
				# Files creation
				my $pseudo_ffn_fasta_file = create_fasta_file($genbank_file,".pffn",$output_dir) if ($ffn == 1);
				my $pseudo_faa_fasta_file = create_fasta_file($genbank_file,".pfaa",$output_dir) if ($faa == 1);
				
				if ($ffn == 1) {
					my $nb_seq_ffn = scalar(@pseudo_Seq_objects_ffn);
					for (my $i=0;$i<=$nb_seq_ffn-1;$i++) {
						$pseudo_ffn_fasta_file->write_seq($pseudo_Seq_objects_ffn[$i]);
					}
				}
				
				if ($faa == 1) {
					my $nb_seq_faa = scalar(@pseudo_Seq_objects_faa);
					for (my $i=0;$i<=$nb_seq_faa-1;$i++) {
						$pseudo_faa_fasta_file->write_seq($pseudo_Seq_objects_faa[$i]);
					}
				}
			}	
		}
		} #ma nouvelle accolade
		}
}


sub to_ffn {
	my ($feat_object,$ref_sequence_info,$organism,$sequence,$pseudo_bool) = @_;
	
	my $ID_gene;
	
	my %sequence_info = %$ref_sequence_info;
	my ($start,$end,$strand,$gene_seq) = location($feat_object,$sequence);
	my $gene_location;
	if ($strand == -1) {
		$gene_location = ":c".$end."-".$start;
	} else {
		if ($strand == 1) {
			$gene_location = ":".$start."-".$end;
		}
	}
		
	if ($pseudo_bool == 0) {
		my $ref_hash_CDS = ffn_faa_common_informations($feat_object);
		$ID_gene = ID_ffn_string($ref_hash_CDS,$sequence_info{"accession"},$sequence_info{"version"},$gene_location,$organism);
	} else {
		if ($pseudo_bool == 1) {
			my $ref_hash_CDS = extract_all_values($feat_object,"locus_tag","note","product");
			my %hash_CDS = %$ref_hash_CDS;
			
			my $ID_locus = '';
			my $ID_note = '';
			my $ID_product = '';
			if (exists($hash_CDS{"locus_tag"})) {
				$ID_locus = "locus|".$hash_CDS{"locus_tag"}."|";
			}
			if (exists($hash_CDS{"note"})) {
				my $note = $hash_CDS{"note"};
				$ID_note = " $note";
			}
			if (exists($hash_CDS{"product"})) {
				my $product = $hash_CDS{"product"};
				$ID_product = " $product";
			}
			$ID_gene = $ID_locus.$gene_location.$ID_product.$ID_note;
		}
	}
	
	return ($ID_gene,$gene_seq);
	
}

sub to_faa {
	my ($feat_object,$ref_sequence_info,$organism,$sequence,$pseudo_bool) = @_;
	
	my $ID_protein;
	my $translation;
	
	
	my %sequence_info = %$ref_sequence_info;
	my ($start,$end,$strand,$gene_seq) = location($feat_object,$sequence);
	my $gene_location;
	if ($strand == -1) {
		$gene_location = ":c".$end."-".$start;
	} else {
		if ($strand == 1) {
			$gene_location = ":".$start."-".$end;
		}
	}	
	
	if ($pseudo_bool == 0) {
		my $ref_hash_CDS = ffn_faa_common_informations($feat_object);
		my %hash_CDS = %$ref_hash_CDS;
		$translation = $hash_CDS{"translation"};
		
		$ID_protein = ID_faa_string($ref_hash_CDS,$sequence_info{"accession"},$sequence_info{"version"},$gene_location,$organism);
	} else {
		if ($pseudo_bool == 1) {
			my $ref_hash_CDS = extract_all_values($feat_object,"locus_tag","note","product");
			my %hash_CDS = %$ref_hash_CDS;
			
			my $ID_locus = '';
			my $ID_note = '';
			my $ID_product = '';
			if (exists($hash_CDS{"locus_tag"})) {
				$ID_locus = "locus|".$hash_CDS{"locus_tag"}."|";
			}
			if (exists($hash_CDS{"note"})) {
				my $note = $hash_CDS{"note"};
				$ID_note = " $note";
			}
			if (exists($hash_CDS{"product"})) {
				my $product = $hash_CDS{"product"};
				$ID_product = " $product";
			}
			$ID_protein = $ID_locus.$ID_product.$ID_note;
		}
	}
	
	return($ID_protein,$translation);
}

sub to_frn {
	my($feat_object,$ref_sequence_info,$primary_tag,$sequence) = @_;
	
	my %sequence_info = %$ref_sequence_info;
	my $accession = $sequence_info{"accession"};

	my $ref_hash_RNA = extract_all_values($feat_object,"product","locus_tag","gene");
	my ($RNA_start,$RNA_end,$RNA_strand,$RNA_seq) = location($feat_object,$sequence);
	my $RNA_location_string = ":".$RNA_start."-".$RNA_end;
	my $ID_RNA = ID_RNA_string($ref_hash_RNA,$primary_tag,$accession,$RNA_location_string);	
	
	return($ID_RNA,$RNA_seq);
}



sub ffn_faa_common_informations {
	my ($feat_object) = @_;

	my $locus_tag;
	my $ref_hash_CDS = extract_all_values($feat_object,"db_xref","protein_id","product","locus_tag","translation");
	my %hash_CDS = %$ref_hash_CDS;
	if (exists($hash_CDS{"db_xref"})) {
		$hash_CDS{"db_xref"} =~ s/GI://;
	}	

	return(\%hash_CDS);
}




sub create_fasta_file {
	my ($genbank_file,$extension,$output_dir) = @_;
	print "\t...Create_fasta_file function called for $extension\n";
	my $file_name_to_create;
	if ($output_dir eq '') {
		$file_name_to_create = extension_change($genbank_file,$extension);
	} else {
		$file_name_to_create = path_to_output_file($genbank_file,$extension,$output_dir);
	}
	
	# verbose => -1 : avoid to have warnings about the ID of the fasta file (No whitespace allowed in FASTA ID)
	my $fasta_file = Bio::SeqIO->new(-file => ">$file_name_to_create", -format => 'fasta', -verbose => -1);
	$fasta_file->width(70);
	
	return($fasta_file);	
}

sub create_gff_file {
	my ($genbank_file,$extension,$output_dir) = @_;
	print "\t...Create_gff_file function called\n";	
	my $file_name_to_create;
	if ($output_dir eq '') {
		$file_name_to_create = extension_change($genbank_file,$extension);
	} else {
		$file_name_to_create = path_to_output_file($genbank_file,$extension,$output_dir);
	}
	my $GFF_IO = Bio::Tools::GFF->new(-file => ">$file_name_to_create", -gff_version => 3);
	
	return($GFF_IO);
}

sub extension_change {
	my ($file_name,$extension) = @_;
	
	my $new_file_name = $file_name;
	
	####################
	# 2012/02/09 modif #
	####################
	my @file_name_split = split(/\./,$file_name);
	my $file_name_split_length = scalar(@file_name_split);
	# Last element, filename may contain several '.'
	my $last_element = $file_name_split_length - 1;
	my $genbank_extension = $file_name_split[$last_element];
	# $new_file_name =~ s/.genbank/_with_GeneID$extension/;
	$new_file_name =~ s/.$genbank_extension/$extension/;
	####################
	
	return($new_file_name);	
}

sub path_to_output_file {
	my ($path_to_file,$extension,$output_dir) = @_;
	
	my $new_path_to_file;
	
	# Extract filename
	my @path_to_file_split = split(/\//,$path_to_file);
	my $path_to_file_split_length = scalar(@path_to_file_split);
	my $last_element = $path_to_file_split_length - 1;
	my $file_name = $path_to_file_split[$last_element];
	
	# Extension change
	my @file_name_split = split(/\./,$file_name);
	my $file_name_split_length = scalar(@file_name_split);
	# Last element, filename may contain several '.'
	$last_element = $file_name_split_length - 1;
	my $genbank_extension = $file_name_split[$last_element];
	
	$file_name =~ s/.$genbank_extension/$extension/;
	$new_path_to_file = $output_dir."/".$file_name;
	
	return($new_path_to_file);	
}

sub extract_all_values {
	my (@args) = @_;
	my $feature = $args[0];
	my $nb_values = scalar(@args) - 1;
	my %hash_return;
		
	for (my $i=1;$i<=$nb_values;$i++) {
		my $tag = $args[$i];
		if ($feature->has_tag($tag)) {
			my $value = ($feature->get_tag_values($tag))[0];
			if ($tag eq "db_xref") {
				# there may be several db_xref fields in a GenBank feature, all with the format: key:value
				my @values = $feature->get_tag_values($tag);
				my $nb_tag_values = scalar(@values);
				for (my $j=0;$j<=$nb_tag_values-1;$j++) {
					my $tag_value = $values[$j];
					if ($tag_value =~ /(\w+):(\d+)/) {
						my $sub_tag = $1;
						my $sub_value = $2;
						$hash_return{$sub_tag} = $sub_value;
						print "sub_tag: $sub_tag | sub_value: $sub_value\n";
					}
				}
			} else {
				$hash_return{$tag} = $value;
			}
		}
	}
	
	return(\%hash_return);	
}

sub extract_value {
	my ($feature,$tag) = @_;
	
	my $value = '';
	
	if ($feature->has_tag($tag)) {
			$value = ($feature->get_tag_values($tag))[0];
	}	
	
	return($value);	
}

sub location {
	my ($feature,$sequence) = @_;
	
	my $split_location = Bio::Location::Split->new();
	$split_location = $feature->location();
	my $seq_string_input = $sequence->seq;
	my $seq_string = '';
	my @all_sublocations = $split_location->each_Location();

	my @all_substrings;
	my $substring;
	

	foreach my $sublocation(@all_sublocations) {
		my $substart = $sublocation->start();
		my $subend = $sublocation->end();
		my $substrand = $sublocation->strand();
		my $string_to_substr = $seq_string_input;
		if ($substrand == -1) {
			$string_to_substr = substr($string_to_substr,$substart-1,$subend-$substart+1); # in genbank file, first nucleotide is number 1, in a string first caracter is number 0
			$substring = reverse_complement_IUPAC($string_to_substr);
		} else {
			$substring = $sequence->subseq($sublocation);
		}
		push(@all_substrings,$substring);
	}
	
	my $start = $all_sublocations[0]->start();
	my $end = $all_sublocations[$#all_sublocations]->end();
	my $strand = $all_sublocations[0]->strand; # all sublocations have the same strand value
	
	my $nb_substrings = scalar(@all_substrings);
	my $i;
	if ($strand == -1) {
		for ($i=$nb_substrings;$i>0;$i--) {
			$seq_string .= $all_substrings[$i-1];
		}
	} else {
		for ($i=0;$i<=$nb_substrings-1;$i++) {
			$seq_string .= $all_substrings[$i];
		}
	}
	
	return($start,$end,$strand,$seq_string);
}

sub reverse_complement_IUPAC {
	my ($seq_string_to_revcom) = @_;
	
	my $revcom = reverse($seq_string_to_revcom);
	$revcom =~ tr/ACGTMKRYBDHVacgtmkrybdhv/TGCAKMYRVHDBtgcakmyrvhdb/;

	return($revcom);	
}



sub write_id_and_seq {
	my ($file,$id,$seq) = @_;
	
	my $seq_object = Bio::Seq->new(-id => $id, -seq => $seq);
	$file->write_seq($seq_object);
}

sub ID_ffn_string {
	my ($ref_hash_CDS,$accession,$version,$gene_location,$organism) = @_;
	
	my %hash_CDS = %$ref_hash_CDS;
	my $ID_product = '';
	my $ID_locus_tag = '';
	my $ID_GeneID = '';
	
	my $version_to_print = '';
	if (defined($version)) {
		$version_to_print .= ".$version";
	}
	
	####################
	# 2012/02/09 modif #
	####################
	my $ID_GI = '';
	if (exists($hash_CDS{"GI"})) {
		$ID_GI = "gi|".$hash_CDS{"GI"}."|";
	}	
	####################
	
	if (exists($hash_CDS{"GeneID"})) {
		$ID_GeneID = "GeneID|".$hash_CDS{"GeneID"}."|";
	}
	if(exists($hash_CDS{"product"})) {
		$ID_product = " ".$hash_CDS{"product"};
		# if ($hash_CDS{"product"} eq "hypothetical protein") {
			# $ID_locus_tag = " ".$hash_CDS{"locus_tag"};
		# }
	}
	if (exists($hash_CDS{"locus_tag"})) {
		$ID_locus_tag = " ".$hash_CDS{"locus_tag"};
	}
		
	####################
	# 2012/02/09 modif #
	####################
	# my $ID_gene = "ref|".$accession.".".$version."|".$ID_GeneID.$gene_location.$ID_product.$ID_locus_tag." [".$organism."]";
	# my $ID_gene = $ID_GI."ref|".$accession.".".$version."|".$gene_location.$ID_product.$ID_locus_tag." [".$organism."]";
	####################
	my $ID_gene = $ID_GI."ref|".$accession.$version_to_print."|".$gene_location.$ID_product.$ID_locus_tag." [".$organism."]";	
	
	return($ID_gene);
}


sub ID_RNA_string {
	my ($ref_hash,$primary_tag,$accession,$location_string) = @_;
	
	my %hash_RNA = %$ref_hash;
	my $ID_product = '';
	my $ID_gene =  '';
	my $ID_locus_tag = '';
	
	if (exists($hash_RNA{"product"})) {
		if ($primary_tag eq "tRNA") {
			my @tRNA_product = split(/-/,$hash_RNA{"product"});
			$ID_product = "|".$tRNA_product[1]." ".$tRNA_product[0];
		} else {
			$ID_product = "|".$hash_RNA{"product"};
		}
	}
	if (exists($hash_RNA{"gene"})) {
		$ID_gene = "| [gene=".$hash_RNA{"gene"}."]";
	}
	if (exists($hash_RNA{"locus_tag"})) {
		$ID_locus_tag = " [locus_tag=".$hash_RNA{"locus_tag"}."]";
	}
	
	my $ID_RNA = "ref|".$accession.'|'.$location_string.$ID_product.$ID_gene.$ID_locus_tag;

	return($ID_RNA);

}

sub ID_faa_string {
	my ($ref_hash_CDS,$accession,$version,$gene_location,$organism) = @_;
	my %hash_CDS = %$ref_hash_CDS;
	
	my $ID_GI = '';
	my $ID_GeneID = '';
	my $ID_protein_id = '';
	my $ID_product = '';
	my $ID_locus_tag = '';
	
	my $version_to_print = '';
	if (defined($version)) {
		$version_to_print .= ".$version";
	}
	
	if (exists($hash_CDS{"GI"})) {
		$ID_GI = "gi|".$hash_CDS{"GI"}."|";
	}
	if (exists($hash_CDS{"protein_id"})) {
		$ID_protein_id = "ref|".$hash_CDS{"protein_id"}."|";
	}
	if (exists($hash_CDS{"GeneID"})) {
		$ID_GeneID = "GeneID|".$hash_CDS{"GeneID"}."|";
	}
	if(exists($hash_CDS{"product"})) {
		$ID_product = " ".$hash_CDS{"product"};
		# if ($hash_CDS{"product"} eq "hypothetical protein") {
			# $ID_locus_tag = " ".$hash_CDS{"locus_tag"};
		# }
	}
	if (exists($hash_CDS{"locus_tag"})) {
		$ID_locus_tag = " ".$hash_CDS{"locus_tag"};
	}
	
	####################
	# 2012/02/09 modif #
	####################
	# my $ID_protein = $ID_GI.$ID_protein_id.$ID_GeneID.$ID_product.$ID_locus_tag." [".$organism."]";
	# my $ID_protein = $ID_GI."ref|".$accession.".".$version."|".$gene_location.$ID_protein_id.$ID_product.$ID_locus_tag." [".$organism."]";
	####################
	my $ID_protein = $ID_GI."ref|".$accession.$version_to_print."|".$gene_location.$ID_protein_id.$ID_product.$ID_locus_tag." [".$organism."]";
	
	return($ID_protein);
	
}

1;
