#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
#####
source /config/env/uploader.env
function cleannzb() {
downloadpath=/move
TARGET_FOLDER="${downloadpath}/{nzb,sabnzbd,nzbget}"
FIND=$(which find)
FIND_BASE1='-type f'
FIND_BASE2='-type d'
FIND_SIZE='-size -100M'
FIND_MINAGE='-cmin +5'
FIND_ACTION1='-not -path "**_UNPACK_**" -exec rm -rf \{\} \; >>/dev/null 2>&1'
FIND_ACTION2='-regex ".*/.*sample.*\.\(avi\|mkv\|mp4\|vob\)" -not -path "**_UNPACK_**" -exec rm -rf \{\} \; >>/dev/null 2>&1'
FIND_ACTION3='-name "**_FAILED_**" -exec rm -rf \{\} \; >>/dev/null 2>&1'

command1="${FIND} ${TARGET_FOLDER} ${FIND_BASE1} ${FIND_SIZE} ${FIND_MINAGE} ${FIND_ACTION1}"
command2="${FIND} ${TARGET_FOLDER} ${FIND_BASE1} ${FIND_SIZE} ${FIND_MINAGE} ${FIND_ACTION2}"
command2="${FIND} ${TARGET_FOLDER} ${FIND_BASE2} ${FIND_MINAGE} ${FIND_ACTION3}"

eval "${command1}"
eval "${command2}"
eval "${command3}"
}

function empty_folder() {
downloadpath=/move
TARGET_FOLDER="${downloadpath}/"
FIND=$(which find)
FIND_BASE='-type d'
FIND_EMPTY='-empty'
FIND_MINDEPTH='-mindepth 2'
FIND_MINAGE='-cmin +5'
FIND_ACTION='-delete >>/dev/null 2>&1'
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
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE} \( ${condition} \) ${FIND_MINAGE} ${FIND_EMPTY} ${FIND_ACTION}"
eval "${command}"
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
if [ "$CAPACITY" -gt "${CAPACITY_LIMIT}" ]; then
    mapfile -t files < <(eval find ${downloadpath} -type f -printf '%T+ %p\n' | sort | cat | awk '{print $2}')
     for i in "${files[@]}"; do
        if [ "$CAPACITY" -le "${CAPACITY_LIMIT}" ]; then
           echo "cleaning done || $CAPACITY is lower as ${CAPACITY_LIMIT}"
        else
           rm -rf "$i" >>/dev/null 2>&1
           continue
        fi
    done
fi
}

cleaning() {
 while true; do
    cleanup
    sleep 10
    empty_folder
    sleep 10
    cleannzb
    sleep 10
 done
}
# keeps the function in a loop
balls=0
while [[ "$balls" == "0" ]]; do cleaning; done
#EOF
