#!/bin/bash

set -e
#set -x

function erx()
{
    echo "$@" >&2
    exit 1
}

if [ ! $# -eq 3 ]; then
    erx "usage: $(basename $0) metric file.1 file.2"
fi

if [ ! -f "$2" ]; then erx "file '$2' does not exist"; fi
if [ ! -f "$3" ]; then erx "file '$3' does not exist"; fi

b2=$(basename $2)
b3=$(basename $3)

awk -F ' t=' '{ if (NF != 0) print $2 }' "$2" > "$2.parsed"
awk -F ' t=' '{ if (NF != 0) print $2 }' "$3" > "$3.parsed"

paste "$2.parsed" "$3.parsed" > $(dirname $2)/$b2-$b3.dat

cat <<EOF
library('ggplot2')
library('reshape')

## Generate a scatterplot
dat <- read.table('$b2-$b3.dat')
comb <- stack(list(default = dat\$V1, smart = dat\$V2))
png("rcmpevts.png", width = 1024, height = 768, res = 128)
p <- ggplot(as.data.frame(comb), aes(x = rep(seq(1:length(dat\$V1)), 2), y = comb\$values, color = factor(comb\$ind)))
p <- p + geom_point() + geom_smooth()
p <- p + labs(x = "event generation (1st, 2nd, 3rd, ..., n-th)", y = "time (msec)", colour = "Track Manager")
p <- p + opts(title = "Time spent in $1")
p
dev.off()

## Generate a scatterplot with the pair-wise deltas of
## time(default) vs. time(smart)
dat <- read.table('$b2-$b3.dat')
df <- data.frame(x = seq(1, length(dat\$V1)), y = dat\$V1-dat\$V2)
png("rcmpevts2.png", width = 1024, height = 768, res = 128)
p <- ggplot(df) + geom_point(aes(x = x, y = y, size = abs(y))) + geom_smooth(aes(x = x, y = y))
p <- p + labs(x = "event generation (1st, 2nd, 3rd, ..., n-th", y = "time(default) - time(smart) (msec)", size = "difference")
p <- p + opts(title = "The difference in time spent in $1")
p
dev.off()

## Generate the plot of empirical cumulative distribution function (ecdf)
## The empirical cdf 'F(x)' is defined as the proportion of 'X' values less than
## or equal to 'x'.
dat <- read.table('$b2-$b3.dat')
names(dat) <- c('Default', 'Smart')
mdf <- melt(dat)
mdf <- ddply(mdf, .(variable), transform, ecd = ecdf(value)(value))
png("rcmpevts3.png", width = 1024, height = 768, res = 128)
p <- ggplot(mdf, aes(x = value, y = ecd))
p <- p + geom_line(aes(group = variable, colour = variable))
p <- p + labs(x = "time (msec)")
p <- p + opts(title = "Plot of empirical cumulative distribution function")
p
dev.off()

EOF
