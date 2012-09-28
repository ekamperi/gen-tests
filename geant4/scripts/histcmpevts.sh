#!/bin/bash
#
# histcmpevts - generate R code that plots two Cycle Per Instructions
# histograms in the same graph to allow for visual comparison
#
# USAGE: histcmpevts file | R --vanilla	# generates file.png
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

b1=$(basename $1)

cat <<EOF
library(ggplot2)
dat <- read.table('$b1', sep='\t')

x <- dat\$V1
y <- dat\$V2

x <- x[!is.na(x)]
y <- y[!is.na(y)]

myx <- data.frame(cache_misses = x)
myy <- data.frame(cache_misses = y)

myx\$StackManager <- 'Default'
myy\$StackManager <- 'Smart'

my <- rbind(myx, myy)

png("$b1.png", width=1024, height=768, res=128)
ggplot(my, aes(cache_misses, fill=StackManager))		\
	   + geom_density(alpha = 0.2)				\
	   + xlab("Time spent in ::ProcessOneEvent() (msec)")	\
	   + opts(title = "$b1")
dev.off()
EOF