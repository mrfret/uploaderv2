#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
######## FUNCTIONS ##########
downloadpath=/move
CLEANUPDOWN=${CLEANUPDOWN:-null}
if [ "${CLEANUPDOWN}" == 'null' ] || [ "${CLEANUPDOWN}" == 'false' ]; then
   CLEANUPDOWN=7
else 
   CLEANUPDOWN=${CLEANUPDOWN}
fi

function emptyfolder() {
downloadpath=/move
TARGET_FOLDER="${downloadpath}/"
FIND=$(which find)
FIND_BASE='-type d'
FIND_EMPTY='-empty'
FIND_MINDEPTH='-mindepth 2'
FIND_ACTION='-delete 1>/dev/null 2>&1'
FIND_ADD_NAME='-o -path'
WANTED_FOLDERS=(
    '**torrent/**'
    '**nzb/**'
    '**sabnzbd/**'
    '**filezilla/**'
    '**nzbget/**'
    '**rutorrent/**'
    '**qbittorrent/**'
    '**jdownloader2/**'
    '**deluge/**'
	)
condition="-not -path '${WANTED_FOLDERS[0]}'"
for ((i = 1; i < ${#WANTED_FOLDERS[@]}; i++))
do
  condition="${condition} ${FIND_ADD_NAME} '${WANTED_FOLDERS[i]}'"
done
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE} \( ${condition} \) ${FIND_EMPTY} ${FIND_ACTION}"
eval ${command}
}

cleaning() {
 while true; do
    bash /app/cleanup/deleteoldesfile.sh
    sleep 5
    emptyfolder
    sleep 5
 done
}


# keeps the function in a loop
cheeseballs=0
while [[ "$cheeseballs" == "0" ]]; do cleaning; done
#EOF
