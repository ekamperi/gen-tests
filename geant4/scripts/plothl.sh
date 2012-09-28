#!/bin/bash
#
# This script operates on a file of the following form:
#
# parent=0xeaf48b0 Mismatch=0 Hits=14814 Misses=4976 load_factor=0.0013244897127151 max_load_factor=1 size()=2841
# parent=0xeaf48b0 Mismatch=0 Hits=24978 Misses=7463 load_factor=0.0018680853536353 max_load_factor=1 size()=4007
# parent=0xa6c65f0 Mismatch=0 Hits=23890 Misses=2136 load_factor=0.0009958149166777 max_load_factor=1 size()=2136
# ...
#
# For every parent (G4CrossSectionDataStore) it plots the hits/(hits+misses)
# ratio and the load factor.

# Keep only parent, hits, misses, load and size
awk         '{ print $1, $3, $4, $5, $7  }' "$1" |
awk -F' |=' '{ print $2, $4, $6, $8, $10 }' > "$1".ready

R --vanilla<<EOF
library('ggplot2')

df <- read.table('$1.ready', colClasses=c("factor", rep("numeric", 4)))
names(df) <- c("store", "hits", "misses", "load", "size")

png("allhits.png", width = 1024, height = 768, res = 128)
p1 <- ggplot(df, aes(x=1:length(store), y=hits/(hits+misses), color=store))
p1 <- p1 + geom_point()
p1 <- p1 + xlab("Sample #") + ylab("hits/(hits+misses)")
p1
dev.off()

png("allload.png", width = 1024, height = 768, res = 128)
p2 <- ggplot(df, aes(x=1:length(store), y=load, color=store))
p2 <- p2 + geom_line()
p2 <- p2 + xlab("Sample #") + ylab("load factor (0-1)")
p2
dev.off()

genplots <- function(d, verbose=FALSE) {

    stores <- unique(df\$store)

    for (i in 1:length(stores)) {
	if (verbose == TRUE) print(paste("Generating plot #: ", i, sep=""))

	tmpdf <- df[df\$store == stores[[i]], ]

	png(paste(i, "hits.png", sep=""), width = 1024, height = 768, res = 128)
	p <- ggplot(data=tmpdf, aes(x=1:length(store), y=hits/(hits+misses)))
	p <- p + geom_point()
	if (length(tmpdf\$hits) > 1 && length(tmpdf\$hits) < 100) p <- p + geom_line()
	p <- p + xlab("Sample #") + ylab("hits / (hits + misses)")
	p <- p + opts(title=paste("Store=", tmpdf[1,]\$store, sep=""))
	print(p)
	dev.off()

	png(paste(i, "load.png", sep=""), width = 1024, height = 768, res = 128)
	p <- ggplot(data=tmpdf, aes(x=1:length(store), y=load))
	p <- p + geom_line()
	p <- p + xlab("Sample #") + ylab("load factor (0-1)")
	p <- p + opts(title=paste("Store=", tmpdf[1,]\$store, sep=""))
	print(p)
	dev.off()
    }
}

genplots(df, verbose=TRUE)
EOF
