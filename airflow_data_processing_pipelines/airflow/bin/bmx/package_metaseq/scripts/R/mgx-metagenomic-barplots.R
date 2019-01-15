#!/usr/bin/env Rscript

c20 <- c(
	rgb(60,90,171, maxColorValue=255),
	rgb(147,198,55, maxColorValue=255),
	rgb(242,94,54, maxColorValue=255),
	rgb(254,106,173, maxColorValue=255),
	rgb(83,43,11, maxColorValue=255),
	rgb(46,72,85, maxColorValue=255),
	rgb(228,165,55, maxColorValue=255),
	rgb(50,204,124, maxColorValue=255),
	rgb(87,106,252, maxColorValue=255),
	rgb(93,32,78, maxColorValue=255),
	rgb(214,5,82, maxColorValue=255),
	rgb(148,131,78, maxColorValue=255),
	rgb(78,167,237, maxColorValue=255),
	rgb(30,129,41, maxColorValue=255),
	rgb(250,152,242, maxColorValue=255),
	rgb(206,35,169, maxColorValue=255),
	rgb(246,133,106, maxColorValue=255),
	rgb(135,126,28, maxColorValue=255),
	rgb(168,55,15, maxColorValue=255),
	rgb(253,72,115, maxColorValue=255)
)

# RECUPERATION DES ARGUMENTS PASSES EN PARAMETRES
args <- commandArgs(trailingOnly=TRUE)

# PATH VERS LA MATRICE CONSOLIDEE
path_to_matrix <- args[1]

# PATH VERS LE FICHIER DE STAT
path_to_stats <- args[2]

# PATH VERS LE REPERTOIRE DE SORTIE
path_to_output_file <- args[3]

# PATH VERS LE FICHIER DE SORTIE (DONNEES POUR BARPLOT)
path_to_output_data_directory <- args[4]

# ACTION : FIGURE OU PAS FIGURES ?
action <- args[5]

# LECTURE DE LA MATRICE
cleanmatrixconsolidated <- read.table( path_to_matrix, h=T, sep="\t", check.names=FALSE)

# # AJOUT NOUVELLE COLONNE CONTENANT LA MEDIANE DU NOMBRE DE READS POUR UN TAXON EN FONCTION DES ECHANTILLONS COMPARES
# cleanmatrixconsolidated[ , "Median" ] <- apply( cleanmatrixconsolidated[ , 4:length(cleanmatrixconsolidated) ], 1, median )

# # ON TRI LE DATAFRAME EN FONCTION DE LA VALEUR DE LA MEDIANE OBTENUE --> DE LA PLUS GRAND A LA PLUS PETITE
# cleanmatrixconsolidatedsorted <- cleanmatrixconsolidated[ with( cleanmatrixconsolidated, order(-Median) ), ]

# LECTURE DU FICHIER DE STATS
stats <- read.table( path_to_stats, sep="\t", check.names=FALSE )

#LABELS DES ECHANTILLONS
samples <- stats[ ,1]

first_column_reads <- 3 + 1
last_column_reads <- 3 + length(samples)

first_column_prop <- 3 + length(samples) + 1
last_column_prop <- length(cleanmatrixconsolidated)

# NOMBRE TOTAL DE READS
total_number_of_reads <- stats[ , 1:2]

# ON CALCUL LA PROPORTION DE CHAQUE TAXON DANS CHAQUE ECHANTILLON
for( sample in samples ){
	
	# NOMBRE TOTAL DE READS DE L'ECHANTILLON
	all_reads <- total_number_of_reads$V2[ total_number_of_reads$V1==sample ]

	# PROPORTION READ PAR TAXON 
	cleanmatrixconsolidated[ , paste(sample,"_prop", sep="") ] <- cleanmatrixconsolidated[ , sample ] / all_reads
}

# AJOUT NOUVELLE COLONNE CONTENANT LA MEDIANE DE LA PROPORTION DU NOMBRE DE READS POUR UN TAXON EN FONCTION DES ECHANTILLONS COMPARES
cleanmatrixconsolidated[ , "Median" ] <- apply( cleanmatrixconsolidated[ , first_column_prop:last_column_prop ], 1, median )

# ON TRI LE DATAFRAME EN FONCTION DE LA VALEUR DE LA MEDIANE OBTENUE --> DE LA PLUS GRAND A LA PLUS PETITE
cleanmatrixconsolidatedsorted <- cleanmatrixconsolidated[ with( cleanmatrixconsolidated, order(-Median) ), ]

# NOMBRE DE READS MAPPES
number_of_mapped_reads <- cleanmatrixconsolidated[ cleanmatrixconsolidated$taxid==1, 4:length( cleanmatrixconsolidated ) - 1 ] # at root level, we get all the mapped reads

# RECUPERATION DES NOM DES TAXONS POUR CHAQUE NIVEAU TAXONOMIQUE
phy <- as.character(cleanmatrixconsolidatedsorted$taxname[ cleanmatrixconsolidatedsorted$rank == "phylum" ])
fam <- as.character(cleanmatrixconsolidatedsorted$taxname[ cleanmatrixconsolidatedsorted$rank == "family" ])
gen <- as.character(cleanmatrixconsolidatedsorted$taxname[ cleanmatrixconsolidatedsorted$rank == "genus" ])
spe <- as.character(cleanmatrixconsolidatedsorted$taxname[ cleanmatrixconsolidatedsorted$rank == "species" ])

# LISTE DE TAXONS POUR CHAQUE NIVEAU TAXO
organisms <- list( phylum=phy, family=fam, genus=gen, species=spe )

# NIVEAUX TAXONOMIQUES
levels <- names(organisms)

##### Several plots ##############
original_marging <- par("mar")
cex.title <- 2.5

data_names <- c()
data_level <- c()
data_barplot <- c()

# SI ON GENERE LES FIGURES
if( action == 0 ) {
	pdf( path_to_output_file, height=10, width=10 )
}

cat("#########################\n#\tBEGIN OUTPUTS\t#\n#########################\n\n")

data <- c()

for( level in levels ){

	cat("Taxonomic level : ", level, "\n")

	# SI ON GENERE LES FIGURES
	if( action == 0 ) {
		
		# MISE EN PLACE DE L'AFFICHAGE
		layout( matrix( c( 1,1,2,3 ), 2, 2, byrow=TRUE ), widths=c(0.5,0.5), heights=c(0.1,0.9) )
		
		# REGLAGE DES MARGES POUR LE PREMIER PLOT
		par( mar=c(0, 0, 0, 0) )

		# PREMIER PLOT : PLOT NULL POUR TITRE
		plot( 0, 0, ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F)
		text( 0, 0.5, labels=paste( "Taxonomic level :", level, sep=" " ), cex=cex.title )
		
	}

	# ON ISOLE TOUTES LES LIGNES DE LA MATRICE CORRESPONDANT AU NIVEAU L
	matrixAtLevel <- cleanmatrixconsolidatedsorted[cleanmatrixconsolidatedsorted$rank==level, ]
	
	# ON FAIT LA SOMME DES READS AU NIVEAU L POUR CHAQUE ECHANTILLON
	sum_reads_at_level <- apply( matrixAtLevel[ , 4:( length( matrixAtLevel[1, ] ) - 1 ) ], 2, sum )

	# ON LISTE LE NOM DES TAXONS AU NIVEAU L
	correct_taxname_at_level <- as.character( organisms[[ which(is.element(levels, level)) ]] )

	# INITIALISATION VECTEUR DE PROPORTIONS
	class_prop <- c()

	# POUR CHAQUE ECHANTILLON
	for( sample in samples ){

		# NOMBRE TOTAL DE READS DE L'ECHANTILLON
		all_reads <- total_number_of_reads$V2[total_number_of_reads$V1==sample]

		# NOMBRE DE READS MAPPES DE L'ECHANTILLON
		mapped_reads <- number_of_mapped_reads[ , which( is.element(colnames(number_of_mapped_reads), sample )) ]

		# NOMBRE TOTAL DE READS NON MAPPES DE L'ECHANTILLON
		unmapped_reads <-  all_reads - mapped_reads

		# PROPORTION DE READS NON MAPPES DE L'ECHANTILLON
		unmapped_reads_proportion <- unmapped_reads / all_reads

		# NOMBRE DE READS DE CHAQUE TAXON AU NIVEAU L
		reads_by_taxon_at_level <- matrixAtLevel[ , which( is.element(colnames(matrixAtLevel), sample) )]

		# PROPORTIONS DE READS DE CHAQUE TAXON AU NIVEAU L
		read_proportions_by_taxon_at_level <- reads_by_taxon_at_level / all_reads

		# NOMBRE DE READ MAPPES AU NIVEAU L 
		mapped_read_at_level <- sum_reads_at_level[ which( is.element( names( sum_reads_at_level ), sample ) ) ]

		# NOMBRE DE READ PAS ENCORE MAPPES AU NIVEAU L
		unmapped_reads_at_level <- all_reads - mapped_read_at_level - unmapped_reads

		# PROPORTION DE READ PAS ENCORE MAPPES AU NIVEAU L
		unmapped_reads_proportion_at_level <- unmapped_reads_at_level / all_reads

		# LIAISON COLONNE PROPORTION UNMAPPED, UNMMAPPED AT THIS RANK, OTHER PROPORTION
		class_prop <- cbind( class_prop, c( unmapped_reads_proportion, unmapped_reads_proportion_at_level, read_proportions_by_taxon_at_level ) )

	} 

	data_names <- c( "Unmapped", "Assign at higher rank", correct_taxname_at_level )
	data_level <- c( rep( level, length( correct_taxname_at_level ) + 2 ) )

	data <- rbind( data, cbind( data_names, data_level, class_prop ) )

	# SI ON GENERE LES FIGURES
	if( action == 0 ) { 

		# REGLAGE MARGES POUR DEUXIEME PLOT : BARPLOTS
		par( mar=c(10,1,0,1) )

		# SI ON A AU MOINS 20 TAXONS PAR NIVEAU ON AFFICHE LES 20 TAXONS AVEC LA MEDIANE LA PLUS ELEVE + LES UNMAPPED
		if ( dim(class_prop)[1] > 22 ){

			# VECTEURS DE NOMS POUR BARPLOTS ET LEGENDE
			class_names <- c( "Others", "Unmapped", "Assign at higher rank", correct_taxname_at_level )

			# VECTEURS DE COULEURS POUR BARPLOTS ET LEGENDE
			class_colors <- c( "black", "dimgrey", "darkgrey", c20 )

			# ON RECUPERE LES 20 MEILLEURS TAXONS + LES UNMAPPED
			top_class_prop <- class_prop[1:22, ]

			# ON RECUPERE TOUS LES AUTRES TAXONS
			down_class_prop <- class_prop[ 23:dim(class_prop)[1], ]

			# SI ON A JUSTE UN TAXON EN PLUS QUE NOTRE LIMITE
			if (dim(class_prop)[1] == 23){
				sum_down_class_prop <- down_class_prop
			}
			
			# SINON ON SOMME TOUTES LES PROPORTIONS DES AUTRES TAXONS
			else {
				sum_down_class_prop <- colSums(down_class_prop)
			}

			# ON AJOUTE CETTE SOMME A NOTRE TABLEAU DE PROPORTION
			class_prop <- rbind( sum_down_class_prop, top_class_prop)

			# NOMS DES COLONNES DU TABLEAU DE PROPORTIONS
			colnames(class_prop) <- samples

			# NOM DES LIGNES  DU TABLEAU DE PROPORTIONS
			rownames(class_prop) <- class_names[1:23]

			# BARPLOT
			barp <- barplot( class_prop, main="", col=class_colors, space=0.1, cex.main=1.5, border=NA, axisnames=F, axes=F )
			text( cbind( barp[1:ncol( class_prop )], -0.02 ), srt=90, adj=1, labels=colnames(class_prop), xpd=TRUE, cex=1.5 )

			# REGLAGE MARGES POUR TROISIEME PLOT : LEGENDE
			par( mar=c(0,0.5,0,0.5) )

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot( 1, 1, xlim=c(0,1), ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F )
			legend( 0, 1, legend=rev(class_names[1:23]), cex=1.5, fill=rev( class_colors[1:length(class_names[1:23])] ), border=NA)
			
		}

		# SI ON A MOINS DE 20 TAXONS PAR NIVEAU ON AFFICHE TOUS LES TAXONS
		else {

			# VECTEURS DE NOMS POUR BARPLOTS ET LEGENDE
			class_names <- c( "Unmapped", "Assign at higher rank", correct_taxname_at_level )

			# VECTEURS DE COULEURS POUR BARPLOTS ET LEGENDE
			class_colors <- c( "black", "dimgrey", c20 )

			# NOMS DES COLONNES DU TABLEAU DE PROPORTIONS
			colnames(class_prop) <- samples

			# NOM DES LIGNES  DU TABLEAU DE PROPORTIONS
			rownames(class_prop) <- class_names

			# BARPLOTS
			barp <- barplot( class_prop, main="", col=class_colors, space=0.1, cex.main=1.5, border=NA, axisnames=F, axes=F )
			text( cbind( barp[1:ncol( class_prop )], -0.02 ), srt=90, adj=1, labels=colnames(class_prop), xpd=TRUE, cex=1.5 )

			# REGLAGE MARGES POUR TROISIEME PLOT : LEGENDE
			par( mar=c(0,0.5,0,0.5) )

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot( 1, 1, xlim=c(0,1), ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F )
			legend( 0, 1, legend=rev(class_names), cex=1.5, fill=rev( class_colors[1:length(class_names)] ), border=NA )

		}
	}
}

cat("\n")

# SI ON GENERE LES FIGURES
if( action == 0 ) {
	dev.off()
}

df <- data.frame( data )
class(samples)
names(df) <- c( "Taxons", "level", as.vector(samples) )
write.table( df, path_to_output_data_directory, quote=FALSE, sep="\t", row.names=FALSE)

cat("\n#########################\n#\tEND OUTPUTS\t#\n#########################\n\n")
