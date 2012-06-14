#!/bin/bash

set -e
set -x

REMOTE_BASE_URL="beket@leaf.dragonflybsd.org:~/public_html/geant4"
ASCIIDOC=( asciidoc -a data-uri
		   -a icons
		   -a toc
		   -a toclevels=4
		   -a numbered
		   -a iconsdir=/usr/share/asciidoc/icons
		   -a stylesdir=/usr/share/asciidoc/stylesheets
		   -a stylesdir=~/adoc-themes/stylesheets
		   -a theme=handbookish )

GITVERS=$(git rev-list --all | wc -l)
GITHASH=$(git rev-list --all | head -n1 | cut -c1-5)

sed "s/@@version@@/0.${GITVERS}-${GITHASH}/"  dtrace.notes >  dtrace.notes2
sed "s/@@version@@/0.${GITVERS}-${GITHASH}/" solaris.notes > solaris.notes2

"${ASCIIDOC[@]}" dtrace.notes2
"${ASCIIDOC[@]}" solaris.notes2

scp  dtrace.html "$REMOTE_BASE_URL"/dtrace.html
scp solaris.html "$REMOTE_BASE_URL"/solaris.html
