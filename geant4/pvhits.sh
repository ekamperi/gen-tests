#!/bin/bash

set -e

# Check argument count

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file" >&2
    exit 1
fi

# Calculate the hits / misses ratio

awk '{
    if ($1) {
	if (!a) {
	    a = $1
	} else {
	    b = $1
	    print 100*(a/b)
	    a = 0
	    b = 0
	}
    }
}' "$1" > "$1.dat"

# We could feed R directly with the heredoc, but instead let us save the
# script in an intermediate file, in case we would like to invoke it,
# independent of the above calculation of hits / misses ratio.

cat <<EOF > "$1.rplot"
library(ggplot2)
png("$1.png", width=1024, height=768, res=128)
df <- read.table('$1.dat')
p <- ggplot(df) + geom_line(aes(x=1:length(df\$V1), y=df\$V1))
p <- p + xlab("simulation time (0.1sec)")
p <- p + ylab("% hits / misses")
p <- p + opts(title="The evolution of hits/misses ratio in G4PhysicsVector::Value()\n(1000 simulated events)")
p
dev.off()
EOF

cat "$1.rplot" | R --vanilla --slave

display "$1.png"
exit 0

