#!/bin/bash

set -e
set -x

REMOTE_BASE_URL="beket@leaf.dragonflybsd.org:~/public_html/geant4"

if [ $# -eq 1 ]; then
    REMOTE_BASE_URL="${REMOTE_BASE_URL}/run-$1"
fi

ASCIIDOC=( asciidoc -a icons
		   -a toc
		   -a toclevels=4
		   -a numbered
		   -a iconsdir=/usr/share/asciidoc/icons
		   -a stylesdir=/usr/share/asciidoc/stylesheets
		   -a stylesdir=~/adoc-themes/stylesheets
		   -a theme=handbookish )

GITVERS=$(git rev-list --all | wc -l)
GITHASH=$(git rev-list --all | head -n1 | cut -c1-5)

if [ $# -eq 1 ]; then
    FILES=("run-$1/smartstack")
else
    FILES=(dtrace solaris smartstack)
fi

for file in ${FILES[@]}
do
    echo "-> Processing document for '${file}'"

    # Add the version number to the documents
    sed "s/@@version@@/0.${GITVERS}-${GITHASH}/" \
	"${file}.notes" > "${file}.notes2"

    # Asciidoc-ify them
    "${ASCIIDOC[@]}" "${file}.notes2"

    # Upload to leaf
    scp "${file}.html" "$REMOTE_BASE_URL"/
done
