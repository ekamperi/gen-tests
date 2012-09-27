#!/bin/bash

cat "$1"			|
/usr/gnu/bin/c++filt -n -p	| awk '

/G4PropagatorInField::ComputeStep/ {
    prev = $0;
    b = 1;
    next
}

/G4SteppingManager::DefinePhysicalStepLength/ {
    if (b != 0) {
	b = 0;
	print NR;
	print prev;
	print $0;
    }
    next
}

{
    b = 0
}'
