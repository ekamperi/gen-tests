#!/bin/bash
#
# histcmpcm - generate R code that plots two cache misses histograms in
# the same graph to allow for visual comparison
#
# USAGE: histcmpcm file | R --vanilla	# generates file.png
#

set -e
#set -x

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file" >&2
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "file '$1' does not exist" >&2
    exit 1
fi

if [[ "$1" == *.dc.* ]]; then
    CMTYPE="Data"
elif [[ $1 == *.ic.* ]]; then
    CMTYPE="Instruction"
else
    CMTYPE=""
    echo "cannot deduce whether data or instruction cache misses from filename" >&2
fi

cat <<EOF
library(ggplot2)
dat <- read.table('$1', sep='\t')

x <- dat\$V1
y <- dat\$V2

x <- x[!is.na(x)]
y <- y[!is.na(y)]

x <- x[x>0 & x<101]
y <- y[y>0 & y<101]

myx <- data.frame(cache_misses = x)
myy <- data.frame(cache_misses = y)

myx\$StackManager <- 'Default'
myy\$StackManager <- 'Smart'

my <- rbind(myx, myy)

png("$1.png", width=1024, height=768, res=128)
ggplot(my, aes(cache_misses, fill=StackManager))	\
	   + geom_density(alpha = 0.2)			\
	   + scale_x_log10(limits = c(0.001, 1000))	\
	   + xlab("% $CMTYPE Cache misses (logscale)")	\
	   + opts(title = "$1")
dev.off()
EOF
