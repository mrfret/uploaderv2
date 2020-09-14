#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
cleaning() {
 while true; do
    cleanup
    sleep 5
    empty_folder
    sleep 5
 done
}
#####
function empty_folder() {
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
function cleanup() {
CAPACITY_LIMIT=${CAPACITY_LIMIT}
downloadpath=/move
if [[ ${CAPACITY_LIMIT} == 'null' ]]; then
    CAPACITY_LIMIT=75
else
    CAPACITY_LIMIT=${CAPACITY_LIMIT}
fi
CAPACITY=$(df -k ${downloadpath} | awk '{gsub("%",""); capacity=$5}; END {print capacity}')
if [ "$CAPACITY" -gt ${CAPACITY_LIMIT} ]; then
      ls -art | while read FILE
    do
        if [ -f $FILE ]
        then
            if rm -rf $FILE
            then
                ## echo "Deleted $FILE"
                CAPACITY=$(df -k ${downloadpath} | awk '{gsub("%",""); capacity=$5}; END {print capacity}')
                if [ "$CAPACITY" -le ${CAPACITY_LIMIT} ]
                then
                     exit
                fi
            fi
        fi
    done
fi
}
# keeps the function in a loop
balls=0
while [[ "$balls" == "0" ]]; do cleaning; done
#EOF
