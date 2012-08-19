#!/bin/bash

set -e

# Check argument count

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file" >&2
    exit 1
fi

# Calculate the hits / misses ratio in the G4PhysicsVector::Value()
# function. The file with the values is generated as per the following
# DTrace invocation. Mind that the address '0xc0' inside Value()
# function needs to be determined manually via diassembling.
#
# dtrace -qn 'pid$target::_ZN15G4PhysicsVector5ValueEd:c0
# {
#     @branch = count();
# }
#
# pid$target::_ZN15G4PhysicsVector5ValueEd:entry
# {
#     @total = count();
# }
#
# tick-100ms
# {
#     printa(@branch);
#     printa(@total);
# }' -c '/home/stathis/geant4.9.5.p01/bin/Linux-g++/full_cms ./bench1_5k.g4' -o values

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
p <- p + opts(title="The evolution of hits/misses ratio in G4PhysicsVector::Value()\n(5000 simulated events)")
p
dev.off()
EOF

cat "$1.rplot" | R --vanilla --slave

display "$1.png"
exit 0
