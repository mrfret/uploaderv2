#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
######## FUNCTIONS ##########
downloadpath=/move
CLEANUPDOWN=${CLEANUPDOWN:-null}
if [[ "${CLEANUPDOWN}" == 'null' ]]; then
   CLEANUPDOWN=7
else 
   CLEANUPDOWN=${CLEANUPDOWN}
fi

cleaning() {
 while true; do
    cleanup_start
    sleep 10
    garbage
    sleep 10
    empty_folder
    sleep 10
 done
}
function empty_folder() {
downloadpath=/move
TARGET_FOLDER="${downloadpath}/"
FIND=$(which find)
FIND_BASE='-type d'
FIND_EMPTY='-empty'
FIND_MINDEPTH='-mindepth 2'
FIND_ACTION='-delete 1>/dev/null 2>&1'
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE} ${FIND_EMPTY} ${FIND_ACTION}"
eval ${command}
}
function cleanup_start() {
downloadpath=/move
TARGET_FOLDER="${downloadpath}/{nzb,torrent,sabnzbd,nzbget,qbittorrent,rutorrent,deluge,jdownloader2}/" 
FIND=$(which find)
FIND_BASE='-mindepth 2 -type d'
FIND_TIME='-ctime +${CLEANUPDOWN}'
FIND_ACTION='-not -path "**_UNPACK_**" -exec rm -rf {} + > /dev/null 2>&1'
command="${FIND} ${TARGET_FOLDER} ${FIND_BASE} ${FIND_TIME} ${FIND_ACTION}"
eval "${command}"
}

function garbage() {
#################
# script by pho #
#################
# basic settings
downloadpath=/move
TARGET_FOLDER="${downloadpath}/{nzb,sabnzbd,nzbget,jdownloader2}/" 
# find files in this folders
FIND_SAMPLE_SIZE='-size -188M'
# advanced settings
FIND=$(which find)
FIND_BASE_CONDITION_WANTED='-type f -amin +600'
FIND_BASE_CONDITION_UNWANTED='-type f'
FIND_MINDEPTH='-mindepth 1'
FIND_ADD_NAME='-o -iname'
FIND_DEL_NAME='! -iname'
FIND_ACTION='-not -path "**_UNPACK_**" -exec rm -rf {} + > /dev/null 2>&1'
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE_CONDITION_WANTED} ${FIND_SAMPLE_SIZE} ${FIND_ACTION}"
eval "${command}"
WANTED_FILES=(
    '*.mkv'
    '*.mpg'
    '*.mpeg'
    '*.avi'
    '*.mp4'
    '*.mp3'
    '*.flac'
    '*.srt'
    '*.idx'
    '*.sub'
    '*.mp4'
)
UNWANTED_FILES=(
    '*.bat'
    'MUST_READ*'
    'win_click2rename*'
    'Thats_the_Board*'
    'What.rar'
    '*.m2ts'
    'abc.xyz.*'
    '*.m3u'
    'Top Usenet Provider*'
    'house-of-usenet.info'
    '*.html~'
    '*KLICK IT*'
    'Click.rar'
    '*.1'
    '*.2'
    '*.3'
    '*.4'
    '*.5'
    '*.6'
    '*.7'
    '*.8'
    '*.9'
    '*.0'
    '*.10'
    '*.11'
    '*.12'
    '*.13'
    '*.14'
    '*.15'
    '*.gif'
    '*sample.*'
    '*.sh'
    '*.pdf'
    '*.doc'
    '*.docx'
    '*.xls'
    '*.xlsx'
    '*.xml'
    '*.html'
    '*.htm'
    '*.exe'
    '*.nzb'
)
#Folder Setting
condition="-iname '${UNWANTED_FILES[0]}'"
for ((i = 1; i < ${#UNWANTED_FILES[@]}; i++))
do
  condition="${condition} ${FIND_ADD_NAME} '${UNWANTED_FILES[i]}'"
done
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE_CONDITION_UNWANTED} \( ${condition} \) ${FIND_ACTION}"
eval "${command}"
for ((i = 0; i < ${#WANTED_FILES[@]}-1; i++))
do
  condition2="${condition2} ${FIND_DEL_NAME} '${WANTED_FILES[i]}'"
done
command="${FIND} ${TARGET_FOLDER} ${FIND_MINDEPTH} ${FIND_BASE_CONDITION_WANTED} \( ${condition2} \) ${FIND_ACTION}"
eval "${command}"
}
# keeps the function in a loop
cheeseballs=0
while [[ "$cheeseballs" == "0" ]]; do cleaning; done
#EOF
