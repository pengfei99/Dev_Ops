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
args <- commandArgs( trailingOnly = TRUE )

# PATH VERS LA MATRICE CONSOLIDEE
path_to_matrix <- args[1]

# PATH VERS LE FICHIER DE STATS
path_to_stats <- args[2]

# PATH VERS LE FICHIER DE SORTIE (BARPLOT)
path_to_output_file_barplot <- args[3]

# PATH VERS LE FICHIER DE SORTIE (DONNEES POUR BARPLOT)
path_to_output_file_data <- args[4]

# ACTION : FIGURE OU PAS FIGURES ?
action <- args[5]

# sample label
sample <- args[6]

# LECTURE DU FICHIER DE STATS
stats <- read.table( path_to_stats, sep = "\t", check.names = FALSE)

# RECUPERATION DE LA LIGNE CORRESPONDANT A L'ECHANTILLON
stats <- stats[ stats$V1 == sample, ]

all_reads <- stats[1,2]
mapped_reads <- stats[1,3]
unmapped_reads <- all_reads - mapped_reads

# LECTURE DE LA MATRICE
matrix <- read.table( path_to_matrix, sep = "\t", h=T, check.names = FALSE )

# RECUPERATION DES TROIS PREMIERES COLONNES ET DE LA COLONNE CORRESPONDANT A L'ECHANTILLON
matrix <- matrix[ , c("taxid", "rank", "taxname", as.character(sample)) ]

# RECUPERATION DES NOM DES TAXONS POUR CHAQUE NIVEAU TAXONOMIQUE
phy <- as.character( matrix$taxname[ matrix$rank == "phylum" ] ) 
fam <- as.character( matrix$taxname[ matrix$rank == "family" ] ) 
gen <- as.character( matrix$taxname[ matrix$rank == "genus" ] )
spe <- as.character( matrix$taxname[ matrix$rank == "species" ] ) 

# LISTE DE TAXONS POUR CHAQUE NIVEAU TAXO
organisms <- list( phylum = phy, family = fam, genus = gen, species = spe )

# NIVEAUX TAXONOMIQUES
levels <- names( organisms )

data_taxon <- c()
data_count_reads <- c()
data_level <- c()

if( action != 1 ) {
	pdf( path_to_output_file_barplot, height = 10, width = 20 )
}

cat("#########################\n#\tBEGIN OUTPUTS\t#\n#########################\n\n")

for( level in levels ){

	cat("Level : ", level, "\n")

	if( action == 0 ) {
		par( mar = c(1,1,1,1) )

		# MISE EN PLACE DE L'AFFICHAGE
		layout( matrix( c( 1,1,2,3 ), 2, 2, byrow = TRUE ), widths = c(0.6,0.4), heights = c(0.1,0.9) )

		# PREMIER PLOT : PLOT NULL POUR TITRE
		plot( 0, 0, ylim = c(0,1), main = "", xlab = "", type = "n", ylab = "", axes = F )

		text( 0, 0.5, labels = paste( "Level :", level, sep = " " ), cex = 2.5 )

	}

	# ON ISOLE TOUTES LES LIGNES DE LA MATRICE CORRESPONDANT AU NIVEAU L
	matrixAtLevel <- matrix[ matrix$rank==level, 3:4 ]
	
	# ON TRIE LES DONNEES DANS L'ORDRE DECROISSANT DE LA COLONNE DES COMTPE DE READS
	matrixSortedAtLevel <- matrixAtLevel[ order( matrixAtLevel[,2], decreasing = T ), ]

	# ON RECUPERE LA COLONNE DES TAXONS DU NIVEAU L
	taxons <- c( "Unmapped", as.character( matrixSortedAtLevel[, 1] ) )

	# ON RECUPERE LA COLONNE DES READS DU NIVEAU L
	reads <- c( unmapped_reads, matrixSortedAtLevel[ , 2] )

	# CREATION FICHIERS CONTENANT L'INFORMATION DES VECTEURS READS ET TAXONS
	data_taxon <- c( data_taxon, taxons )
	data_count_reads <- c( data_count_reads, reads )
	data_level <- c( data_level, rep( level, length(reads) ) )

	#SI ON GENERE LES BARPLOTS
	if( action == 0 ) {

		# VECTEURS DE COULEURS POUR BARPLOTS ET LEGENDE
		colors <-c( "Grey", c20 )

		# MARGES BARPLOTS (21 pour la marge du bas pour que les noms des taxons ne soient pas tronques)
		par( mar = c(21,5,1,1) )

		# SI LE NOMBRE DE TAXON POUR LE NIVEAU TAXONOMIQUE EST SUPERIEUR A 21, ON NE GARDE QUE LES 20 TAXONS LES PLUS REPRESENTE + LES UNMAPPED
		if ( length(reads) > 21 ){

			# BARPLOT DES READS
			bp <- barplot( reads[1:21], ylab= "Reads", ylim=c(0, max(reads)*1.1 ), col=colors, las=3, names.arg = taxons[1:21], beside = TRUE )
			text(bp, reads[1:21], reads[1:21], pos=3)

			# MARGE POUR LA LEGENDE 
			par( mar = c(1,1,1,1) )

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot( 0, 0, xlim = c(0,1), ylim = c(0,1), main = "", xlab = "", type = "n", ylab = "", axes = F )
			legend( 0, 1, legend = rev(taxons[1:21]), cex = 1.5, fill = rev(colors[1:length(taxons[1:21])]) , border = NA)

		}

		# SINON ON GARDE TOUS LES TAXONS
		else {

			# BARPLOT DES READS
			bp <- barplot( reads, ylab= "Reads", ylim=c(0, max(reads)*1.1 ), col=colors, las=3, names.arg = taxons, beside = TRUE )
			text(bp, reads, reads, pos=3)

			# MARGE POUR LA LEGENDE 
			par( mar = c(1,1,1,1) )

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot( 0, 0, xlim = c(0,1), ylim = c(0,1), main = "", xlab = "", type = "n", ylab = "", axes = F )
			legend( 0, 1, legend = rev(taxons), cex = 1.5, fill = rev(colors[1:length(taxons)]) , border = NA)

		}
	}
}

cat("\n")

if( action == 0 ) {
	dev.off()
}

df <- data.frame(data_taxon, data_count_reads, data_level)
names(df) <- c( "Taxons", "#reads", "level" )
write.table( df, path_to_output_file_data, quote = FALSE, sep="\t", row.names = FALSE)

cat("\n#########################\n#\tEND OUTPUTS\t#\n#########################\n\n")