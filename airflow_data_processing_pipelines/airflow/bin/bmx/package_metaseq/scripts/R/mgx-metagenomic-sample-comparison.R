#!/usr/bin/env Rscript

c20 <- c(
	rgb( 60,  90, 171, maxColorValue=255),
	rgb(147, 198,  55, maxColorValue=255),
	rgb(242,  94,  54, maxColorValue=255),
	rgb(254, 106, 173, maxColorValue=255),
	rgb( 83,  43,  11, maxColorValue=255),
	rgb( 46,  72,  85, maxColorValue=255),
	rgb(228, 165,  55, maxColorValue=255),
	rgb( 50, 204, 124, maxColorValue=255),
	rgb( 87, 106, 252, maxColorValue=255),
	rgb( 93,  32,  78, maxColorValue=255),
	rgb(214,   5,  82, maxColorValue=255),
	rgb(148, 131,  78, maxColorValue=255),
	rgb( 78, 167, 237, maxColorValue=255),
	rgb( 30, 129,  41, maxColorValue=255),
	rgb(250, 152, 242, maxColorValue=255),
	rgb(206,  35, 169, maxColorValue=255),
	rgb(246, 133, 106, maxColorValue=255),
	rgb(135, 126,  28, maxColorValue=255),
	rgb(168,  55,  15, maxColorValue=255),
	rgb(253,  72, 115, maxColorValue=255)
)

pch5 <- c(15, 16, 17, 18, 20)

# RECUPERATION DES ARGUMENTS PASSES EN PARAMETRES
args <- commandArgs(trailingOnly=TRUE)

# PATH VERS LA MATRICE CONSOLIDEE
path_to_matrix <- args[1]

# PATH VERS LE FICHIER DE STAT
path_to_stats <- args[2]

# PATH VERS LE REPERTOIRE DE SORTIE
path_to_output_file <- args[3]

# ACTION : FIGURE OU PAS FIGURES ?
action <- args[4]

# LOG : LOG(PROPORTION) OU PAS ?
log <- args[5]

# LECTURE DE LA MATRICE
cleanmatrixconsolidated <- read.delim( path_to_matrix, sep="\t", check.names=FALSE )

# LECTURE DU FICHIER DE STATS
stats <- read.delim( path_to_stats, h=F, sep="\t", check.names=FALSE )

#LABELS DES ECHANTILLONS
samples <- stats[ , 1 ]

first_column_reads <- 3 + 1
last_column_reads <- 3 + length(samples)

first_column_prop <- 3 + length(samples) + 1
last_column_prop <- length(cleanmatrixconsolidated)

# NOMBRE TOTAL DE READS
total_number_of_reads <- stats[ , 1:2 ]

# ON CALCUL LA PROPORTION DE CHAQUE TAXON DANS CHAQUE ECHANTILLON
for( sample in samples ){

	# NOMBRE TOTAL DE READS DE L'ECHANTILLON
	all_reads <- total_number_of_reads$V2[ total_number_of_reads$V1 == sample ]

	# PROPORTION READ PAR TAXON
	cleanmatrixconsolidated[ , paste(sample,"_prop", sep="") ] <- cleanmatrixconsolidated[ , sample ] / all_reads

}

# AJOUT NOUVELLE COLONNE CONTENANT LA MEDIANE DE LA PROPORTION DU NOMBRE DE READS POUR UN TAXON EN FONCTION DES ECHANTILLONS COMPARES
cleanmatrixconsolidated[ , "Median" ] <- apply( cleanmatrixconsolidated[ , first_column_prop:last_column_prop ], 1, median )

# ON TRI LE DATAFRAME EN FONCTION DE LA VALEUR DE LA MEDIANE OBTENUE --> DE LA PLUS GRAND A LA PLUS PETITE
cleanmatrixconsolidatedsorted <- cleanmatrixconsolidated[ with( cleanmatrixconsolidated, order(-Median) ), ]

# NOMBRE DE READS MAPPES
number_of_mapped_reads <- cleanmatrixconsolidated[ cleanmatrixconsolidated$taxid == 1, 4:length( cleanmatrixconsolidated ) - 1 ] # at root level, we get all the mapped reads

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

# SI ON GENERE LES FIGURES
if( action == 0 ) {
	pdf( path_to_output_file, height=7, width=10 )
}

cat("#########################\n#\tBEGIN OUTPUTS\t#\n#########################\n\n")

for( level in levels ){

	cat("Taxonomic level : ", level, "\n")

	# SI ON GENERE LES FIGURES
	if( action == 0 ) {

		# MISE EN PLACE DE L'AFFICHAGE
		layout( matrix( c( 1,1,1,2,3,4 ), 2, 3, byrow=TRUE ), widths=c(0.70,0.15,0.15), heights=c(0.1,0.9) )

		# REGLAGE DES MARGES POUR LE PREMIER PLOT
		par( mar=c(0, 0, 0, 0) )

		# PREMIER PLOT : PLOT NULL POUR TITRE
		plot( 0, 0, ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F )
		text( 0, 0.5, labels=paste( "Taxonomic level :", level, sep=" " ), cex=cex.title )

	}

	# ON ISOLE TOUTES LES LIGNES DE LA MATRICE CORRESPONDANT AU NIVEAU L
	matrixAtLevel <- cleanmatrixconsolidatedsorted[cleanmatrixconsolidatedsorted$rank == level, ]

	# ON FAIT LA SOMME DES READS AU NIVEAU L POUR CHAQUE ECHANTILLON
	sum_reads_at_level <- apply( matrixAtLevel[ , 4:( length( matrixAtLevel[1, ] ) - 1 ) ], 2, sum )

	# ON LISTE LE NOM DES TAXONS AU NIVEAU L
	correct_taxname_at_level <- as.character( organisms[[ which(is.element(levels, level)) ]] )

	# INITIALISATION VECTEUR DE PROPORTIONS
	class_prop <- c()

	# POUR CHAQUE ECHANTILLON
	for( sample in samples ){

		# NOMBRE TOTAL DE READS DE L'ECHANTILLON
		all_reads <- total_number_of_reads$V2[total_number_of_reads$V1 == sample]

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

	# SI ON GENERE LES FIGURES
	if( action == 0 ) {

		# REGLAGE MARGES POUR DEUXIEME PLOT : BARPLOTS
		par( mar=c(12, 5, 0.5, 0.5) )

		# SI ON A AU MOINS 20 TAXONS PAR NIVEAU ON AFFICHE LES 20 TAXONS AVEC LA MEDIANE LA PLUS ELEVE + LES UNMAPPED
		if ( dim(class_prop)[1] > 17 ){

			# VECTEURS DE NOMS POUR BARPLOTS ET LEGENDE
			class_names <- c( "Others", "Unmapped", "Assign at higher rank", correct_taxname_at_level )

			# ON RECUPERE LES 20 MEILLEURS TAXONS + LES UNMAPPED
			top_class_prop <- class_prop[1:17, ]

			# ON RECUPERE TOUS LES AUTRES TAXONS
			down_class_prop <- class_prop[ 18:dim(class_prop)[1], ]

			# SI ON A JUSTE UN TAXON EN PLUS QUE NOTRE LIMITE
			if (dim(class_prop)[1] == 18){
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

			# NOM DES LIGNES DU TABLEAU DE PROPORTIONS
			rownames(class_prop) <- class_names[1:18]

			class_prop[class_prop == 0] <- NA

			if (log == 0){

				matplot(class_prop[4:18, ], ylab="Taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, ylim=c(0,1), xaxt="n", yaxt="n", mgp = c(4, 1, 0), axis=FALSE)
				axis(1, at=seq(1:15), labels=class_names[4:18], las=3)
				axis(2, at=seq(0, 1, length=11), las=2)
				abline(v=seq(1:15), col="grey40")
				abline(h=seq(0, 1,length=11), col="grey40")

				matplot(class_prop[1:3, ], ylab="Taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, ylim=c(0,1), xaxt="n", yaxt="n", mgp = c(4, 1, 0), axis=FALSE)
				axis(1, at=seq(1:3), labels=class_names[1:3], las=3)
				axis(2, at=seq(0, 1, length=11), las=2)
				abline(v=seq(1:3), col="grey40")
				abline(h=seq(0, 1,length=11), col="grey40")

			} else if (log == 1){

				log_class_prop <- log(class_prop)
				min <- round( min(log_class_prop, na.rm = TRUE), 2 )
				max <- round( max(log_class_prop, na.rm = TRUE), 2 )

				matplot(log_class_prop[4:18, ], ylab="Log taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, xaxt="n", yaxt="n", mgp = c(4, 1, 0), ylim=c(min,max), axis=FALSE)
				axis(1, at=seq(1:15), labels=class_names[4:18], las=3)
				axis(2, at=seq(min, max, length=11), las=2, labels=signif(exp(seq(min, max, length=11)), 1))
				abline(v=seq(1:15), col="grey40")
				abline(h=seq(min, max, length=11), col="grey40")

				matplot(log_class_prop[1:3, ], ylab="Log taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, xaxt="n", yaxt="n", mgp = c(4, 1, 0), ylim=c(min,max), axis=FALSE)
				axis(1, at=seq(1:3), labels=class_names[1:3], las=3)
				axis(2, at=seq(min, max, length=11), las=2, labels=signif(exp(seq(min, max, length=11)), 1))
				abline(v=seq(1:3), col="grey40")
				abline(h=seq(min, max, length=11), col="grey40")

			}

			# MARGE POUR LA LEGENDE
			par(mar=c(0.5,0.5,0.5,0.5))

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot(0, 0, xlim=c(0,1), ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F)
			legend("top", legend=samples, pch=pch5, col=c20, pt.cex=2)

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

			class_prop[class_prop == 0] <- NA

			if (log == 0){

				matplot(class_prop[3:length(class_names), ], ylab="Taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, ylim=c(0,1), xaxt="n", yaxt="n", mgp = c(4, 1, 0), axis=FALSE)

				axis(1, at=seq(1:(length(class_names)-2)), labels=class_names[3:length(class_names)], las=3)
				axis(2, at=seq(0, 1, length=11), las=2)
				abline(v=seq(1:15), col="grey40")
				abline(h=seq(0, 1,length=11), col="grey40")

				matplot(class_prop[1:2, ], ylab="Taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, ylim=c(0,1), xaxt="n", yaxt="n", mgp = c(4, 1, 0), axis=FALSE)
				axis(1, at=seq(1:2), labels=class_names[1:2], las=3)
				axis(2, at=seq(0, 1, length=11), las=2)
				abline(v=seq(1:2), col="grey40")
				abline(h=seq(0, 1,length=11), col="grey40")

			} else if (log == 1){

				log_class_prop <- log(class_prop)
				min <- round( min(log_class_prop, na.rm = TRUE), 2 )
				max <- round( max(log_class_prop, na.rm = TRUE), 2 )

				matplot(log_class_prop[3:length(class_names), ], ylab="Log taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, xaxt="n", yaxt="n", mgp = c(4, 1, 0), ylim=c(min,max), axis=FALSE)
				axis(1, at=seq(1:(length(class_names)-2)), labels=class_names[3:length(class_names)], las=3)
				axis(2, at=seq(min, max, length=11), las=2)
				abline(v=seq(1:15), col="grey40")
				abline(h=seq(min, max, length=11), col="grey40")

				matplot(log_class_prop[1:2, ], ylab="Log taxonomic relative abundance", type="p", lty=1, pch=pch5, cex=2, col=c20, xaxt="n", yaxt="n", mgp = c(4, 1, 0), ylim=c(min,max), axis=FALSE)
				axis(1, at=seq(1:2), labels=class_names[1:2], las=3)
				axis(2, at=seq(min, max, length=11), las=2)
				abline(v=seq(1:2), col="grey40")
				abline(h=seq(min, max, length=11), col="grey40")

			}

			# MARGE POUR LA LEGENDE
			par(mar=c(0.5,0.5,0.5,0.5))

			# TROISIEME PLOT : PLOT NULL POUR LEGENDE
			plot(0, 0, xlim=c(0,1), ylim=c(0,1), main="", xlab="", type="n", ylab="", axes=F)
			legend("top", legend=samples, pch=pch5, col=c20, pt.cex=2)

		}
	}
}

cat("\n")

# SI ON GENERE LES FIGURES
if( action == 0 ) {
	dev.off()
}

cat("\n#########################\n#\tEND OUTPUTS\t#\n#########################\n\n")
