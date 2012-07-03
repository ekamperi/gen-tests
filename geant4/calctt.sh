#!/bin/bash

set -e
set -x

benchmarks=(bench1_10.g4 bench1_100.g4 bench1_200.g4 bench1_300.g4 bench1_500.g4 bench1_1k.g4 bench1_5k.g4)
#benchmarks=(bench1_5k.g4)

for j in {1..5};
do
    for bench in "${benchmarks[@]}";
    do
	cat /devices/pseudo/dummy@0:0
	dtrace -n '
		pid$target::*DoEventLoop*:entry                { self->pstart = vtimestamp; } 
		pid$target::*DoEventLoop*:return/self->pstart/ { @ = sum((vtimestamp - self->pstart)/1000000); 
		self->pstart = 0;}' -c \
		'/home/stathis/gen-tests/geant4/geant4.9.5.p01/bin/Linux-g++/full_cms ./'${bench}'' -o \
		    "res-vec-${bench}-$j"
    done
done
