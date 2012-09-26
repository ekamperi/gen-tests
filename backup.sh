#!/bin/bash

set -e
#set -x

user="stathis"
host="10.0.0.3"

declare -A dirs
dirs["/home/stathis/Desktop/MINT 11 BACK/"]="/tank/backup/"
dirs["/home/stathis/Dropbox/"]="/tank/dropbox/Dropbox/"

for dir in "${!dirs[@]}"
do
    echo "-> Syncing directory; source: '${dir}' target: '${dirs[$dir]}'"
    rsync -aCrvz --progress "${dir}"  "${user}@${host}:${dirs[$dir]}"
done
