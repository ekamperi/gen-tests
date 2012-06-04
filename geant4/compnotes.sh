#!/bin/bash

set -e

REMOTE_BASE_URL="beket@leaf.dragonflybsd.org:~/public_html/geant4"

asciidoc  dtrace.notes
asciidoc solaris.notes

scp  dtrace.html "$REMOTE_BASE_URL"
scp solaris.html "$REMOTE_BASE_URL"
