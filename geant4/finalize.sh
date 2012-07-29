#!/bin/bash

#set -e
#set -x

user="stathis"
host="island.quantumachine.net"
remote_base_path="~/public_html/geant4"

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file"
    exit 1
fi

iteration=$1

echo "Downloading run-${iteration}/ directory"
wget -q -r -l1 -R index.html --no-directories -np	\
     --directory-prefix="run-${iteration}"		\
     "http://${host}/~${user}/geant4/run-${iteration}"
(
    cd "run-${iteration}"

    # Events
    cat rcmpevts.rplot  | R --vanilla --slave

    # Cycles Per Instruction
    cat cmpcpits.gplot | gnuplot > cmpcpits.png

    # Data Cache misses
    cat cmpdcmts.gplot | gnuplot > cmpdcmts.png

    # Instruction Cache misses
    cat cmpicmts.gplot | gnuplot > cmpicmts.png

    ############################################################################
    #				HISTOGRAMS				       #
    ############################################################################
    cat histcmpevts.rplot | R --vanilla --slave
    read HISTEVTSDAT <"HIST.EVTSDAT"
    cp "${HISTEVTSDAT}.png" histcmpevts.png

    cat histcmpcpi.rplot | R --vanilla --slave
    read HISTCPIDAT <"HIST.CPIDAT"
    cp "${HISTCPIDAT}.png" histcmpcpi.png

    cat histcmpdcm.rplot | R --vanilla --slave
    read HISTDCMDAT <"HIST.DCMDAT"
    cp "${HISTDCMDAT}.png" histcmpdcm.png

    cat histcmpicm.rplot | R --vanilla --slave
    read HISTICMDAT <"HIST.ICMDAT"
    cp "${HISTICMDAT}.png" histcmpicm.png

    ############################################################################
    #				Upload the results			       #
    ############################################################################
    FILES=(rcmpevts.png rcmpevts2.png cmpcpits.png cmpdcmts.png cmpicmts.png
	   histcmpevts.png histcmpcpi.png histcmpdcm.png histcmpicm.png)

    for file in "${FILES[@]}"
    do
	echo "-> Uploading file '${file}'"
	scp "${file}" "${user}@${host}:${remote_base_path}/run-${iteration}"
    done

    sed "s/@@iteration@@/${iteration}/" smartstack.notes > smartstack.notes2
)

./compnotes.sh ${iteration}
