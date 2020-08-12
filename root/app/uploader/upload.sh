#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
# Logging Functio
####
function log() {
   echo "[Uploader] ${1}"
}
downloadpath=/move
IFS=$'\n'
FILE=$1
GDSA=$2
log "[Upload] Upload started for $FILE using $GDSA"
STARTTIME=$(date +%s)
FILEBASE=$(basename "${FILE}")
FILEDIR=$(dirname "${FILE}" | sed "s#${downloadpath}/##g")
JSONFILE="/config/json/${FILEBASE}.json"
DISCORD="/config/discord/${FILEBASE}.discord"
RCLONEDOCKER="/config/rclone-docker.conf"
PID="/config/pid"
PLEX=${PLEX:-false}
test_2=$(ls /config | grep -c xml)
test_1=$(ls /app | grep -c xml)
if [ ${PLEX} == "false" ]; then
   if [[ ${test_1} == "1" || ${test_2} == "1" ]]; then
      PLEX=true
   fi
fi
BWLIMITSET=${BWLIMITSET}
test_2=$(ls /config | grep -c xml)
test_1=$(ls /app | grep -c xml)
if [ ${BWLIMITSET} == 'null' ]; then
   if [[ ${test_1} == "1" || ${test_2} == "1" ]]; then
      BWLIMITSET=80
   else
      BWLIMITSET=100
   fi
else
   BWLIMITSET=${BWLIMITSET}
fi
GCE=${GCE:-false}
if [ ${GCE} == "false" ]; then
   gcheck=$(dnsdomainname | tail -c 10)
   if [ "$gcheck" == ".internal" ]; then
      GCE=true
   fi
fi
# TITEL=${DISCORD_EMBED_TITEL}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
LOGHOLDUI=${LOGHOLDUI}
TRANSFERS=$(ls /config/pid/ | wc -l)
CHECKERS="$((${TRANSFERS}*2))"
PLEX_JSON="/config/json/${FILEBASE}.bwlimit"
# add to file lock to stop another process being spawned while file is moving
echo "lock" >"${FILE}.lck"
echo "lock" >"${DISCORD}"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
##bwlimitpart
if [[ ${PLEX} == "true" || ${BWLIMITSET} != "null" ]]; then
    BWLIMITSPEED="$(cat ${PLEX_JSON})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
elif [ ${GCE} == "true" ]; then
    BWLIMIT=""
else
    BWLIMIT=""
    BWLIMITSPEED="no LIMIT was set"
fi
touch "${LOGFILE}"
chmod 777 "${LOGFILE}"
#update json file for Uploader GUI
echo "{\"filedir\": \"${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"uploading\",\"logfile\": \"${LOGFILE}\",\"gdsa\": \"${GDSA}\"}" >"${JSONFILE}"
log "[Upload] Starting Upload"
rclone moveto --tpslimit 6 --checkers=${CHECKERS} \
       --config=${RCLONEDOCKER} \
       --log-file="${LOGFILE}" --log-level INFO --stats 2s \
       --no-traverse --user-agent="SomeLegitUserAgent" \
       --drive-chunk-size=${CHUNK}M ${BWLIMIT} \
       "${FILE}" "${REMOTE}:${FILEDIR}/${FILEBASE}"
ENDTIME=$(date +%s)
if [ "${RC_ENABLED}" == "true" ]; then
    sleep 10s && rclone rc vfs/forget dir="${FILEDIR}" --user "${RC_USER:-user}" --pass "${RC_PASS:-xxx}" --no-output
fi
#update json file for Uploader GUI
echo "{\"filedir\": \"/${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"done\",\"gdsa\": \"${GDSA}\",\"starttime\": \"${STARTTIME}\",\"endtime\": \"${ENDTIME}\"}" >"${JSONFILE}"
### send note to discod 
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
   TITEL=${DISCORD_EMBED_TITEL}
   DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
   DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
   LEFTTOUPLOAD=$(du -sh ${downloadpath} --exclude={torrent,nzb,backup,nzbget,jdownloader2,sabnzbd,rutorrent,deluge,qbittorrent} | awk '$2 == "/move/" {print $1}')
   # shellcheck disable=SC2003
   TIME="$((count=${ENDTIME}-${STARTTIME}))"
   duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
   echo "FILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED}M \nUpload queue : ${LEFTTOUPLOAD} \nTime : ${duration} \nActive Transfers : ${TRANSFERS}" >"${DISCORD}"
   msg_content=$(cat "${DISCORD}")
   curl -sH "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
else
   log "[Upload] Upload complete for $FILE, Cleaning up"
fi
#remove file lock
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
   sleep 1
   rm -f "${FILE}.lck" \
         "${PLEX_JSON}" \
         "${PLEX_STREAMS}" \
         "${LOGFILE}" \
         "${PID}/${FILEBASE}.trans" \
         "${DISCORD}" \
         "${JSONFILE}"    
else
   sleep 1
   rm -f "${FILE}.lck" \
         "${PLEX_JSON}" \
         "${PLEX_STREAMS}" \
         "${LOGFILE}" \
         "${PID}/${FILEBASE}.trans" \
         "${DISCORD}"
   sleep "${LOGHOLDUI}"
   rm -f "${JSONFILE}"
fi
##EOF
