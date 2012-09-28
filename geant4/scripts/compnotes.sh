#!/bin/bash

set -e
#set -x

remote_base_url="stathis@island.quantumachine.net:~/public_html/geant4"

if [ $# -eq 1 ]; then
    remote_base_url="${remote_base_url}/run-$1"
fi

asciidoc=( asciidoc -a icons
		   -a toc
		   -a toclevels=4
		   -a numbered
		   -a iconsdir=/usr/share/asciidoc/icons
		   -a stylesdir=/usr/share/asciidoc/stylesheets
		   -a stylesdir=~/adoc-themes/stylesheets
		   -a theme=handbookish )

gitvers=$(git rev-list --all | wc -l)
githash=$(git rev-list --all | head -n1 | cut -c1-5)

if [ $# -eq 1 ]; then
    files=(smartstack.notes)
else
    files=(*.notes)
fi

echo "Files will be uploaded to: ${remote_base_url}"

for file in "${files[@]}"
do
    echo "-> Processing document for '${file}'"

    # Add the version number to the documents
    sed "s/@@version@@/0.${gitvers}-${githash}/" \
	"${file}" > "${file}.2"

    # Asciidoc-ify them
    "${asciidoc[@]}" "${file}.2"

    # Upload to leaf
    scp "${file}.html" "$remote_base_url"/
done
