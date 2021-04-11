#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Copyright (c) 2020 MrDoob
# All rights reserved.
# Logging Function
function log() {
    echo "[Uploader] ${1}"
}
source /config/env/uploader.env
downloadpath=/mnt/downloads
IFS=$'\n'
FILE=$1
GDSA=$2
rjson=/config/rclone/rclone-docker.conf

if grep -q GDSA01C "${rjson}" && grep -q GDSA02C "${rjson}"; then
   DRIVE=TCRYPT
else
   DRIVE=TDRIVE
fi

BANDWITHLIMIT=${BANDWITHLIMIT}
if [ "${BANDWITHLIMIT}" == 'null' ]; then
   BWLIMIT=""
else 
   BANDWITHLIMIT=${BANDWITHLIMIT}
   BWLIMIT="--bwlimit=${BANDWITHLIMIT}"
fi

log "[Upload] Upload started for $FILE using $GDSA to ${DRIVE}"
STARTTIME=$(date +%s)
FILEBASE=$(basename "${FILE}")
FILEDIR=$(dirname "${FILE}" | sed "s#${downloadpath}/##g")
JSONFILE="/config/json/${FILEBASE}.json"
CHECKERS="$((${TRANSFERS}*4))"
DISCORD="/config/discord/${FILEBASE}.discord"
PID="/config/pid"

# add to file lock to stop another process being spawned while file is moving
echo "lock" > "${FILE}.lck"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
#create and chmod the log file so that webui can read it
touch "${LOGFILE}"
chmod 777 "${LOGFILE}"
#update json file for Uploader GUI
echo "{\"filedir\": \"${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"uploading\",\"logfile\": \"${LOGFILE}\",\"gdsa\": \"${GDSA}\"}" >"${JSONFILE}"

log "[Upload] Starting Upload"
rclone moveto --tpslimit 8 --checkers=${CHECKERS} \
    --config "${rjson}" --log-file="${LOGFILE}" --log-level INFO --stats 2s \
    --drive-chunk-size=32M --user-agent=${UAGENT} ${BWLIMIT} \
    "${FILE}" "${REMOTE}:${FILEDIR}/${FILEBASE}"
ENDTIME=$(date +%s)

#update json file for Uploader GUI
echo "{\"filedir\": \"/${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"done\",\"gdsa\": \"${GDSA}\",\"starttime\": \"${STARTTIME}\",\"endtime\": \"${ENDTIME}\"}" >"${JSONFILE}"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
   TITEL=${DISCORD_EMBED_TITEL}
   DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
   DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
   LEFTTOUPLOAD=$(du -sh ${downloadpath}/ --exclude={torrent,nzb,filezilla,backup,nzbget,jdownloader2,sabnzbd,rutorrent,deluge,qbittorrent} | awk '$2 == "/mnt/downloads/" {print $1}')
   # shellcheck disable=SC2003
   TIME="$((count=${ENDTIME}-${STARTTIME}))"
   duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
   echo "FILE: ${DRIVE}/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nUpload queue : ${LEFTTOUPLOAD}Bytes \nTime : ${duration} \nActive Transfers : ${TRANSFERS}" >"${DISCORD}"
   msg_content=$(cat "${DISCORD}")
   curl -sH "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
else
   LEFTTOUPLOAD=$(du -sh ${downloadpath}/ --exclude={torrent,nzb,filezilla,backup,nzbget,jdownloader2,sabnzbd,rutorrent,deluge,qbittorrent} | awk '$2 == "/mnt/downloads/" {print $1}')
   log "[Upload] Upload complete for $FILE, Upload queue : ${LEFTTOUPLOAD}Bytes ,Cleaning up"
fi

if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
   rm -rf "${FILE}.lck" \
          "${PLEX_JSON}" \
          "${LOGFILE}" \
          "${PID}/${FILEBASE}.trans" \
          "${DISCORD}" \
          "${JSONFILE}"
else
   rm -rf "${FILE}.lck" \
          "${PLEX_JSON}" \
          "${LOGFILE}" \
          "${PID}/${FILEBASE}.trans" \
          "${DISCORD}"
   sleep "${LOGHOLDUI}"
   rm -rf "${JSONFILE}"
fi

#<EoF>#
