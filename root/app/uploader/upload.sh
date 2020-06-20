#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
# Logging Functio
####
source /app/functions/functions.sh
######
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
PID="/config/pid"
## plex_process_function
plex_process
## plex_process_function
# add to file lock to stop another process being spawned while file is moving
echo "lock" >"${FILE}.lck"
echo "lock" >"${DISCORD}"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
## bwlimitpart_function
bwlimit_proccess
UPLOADS=${UPLOADS}
CHECKERS="$((${UPLOADS}*2))"
GCE=${GCE}
BWLIMITSET=${BWLIMITSET}
UPLOADS=${UPLOADS}
# PLEX_STREAMS="/config/json/${FILEBASE}.streams"
PLEX_JSON="/config/json/${FILEBASE}.bwlimit"
####
if [ ${PLEX} == 'true' ]; then
    BWLIMITSPEED="$(cat ${PLEX_JSON})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
elif [ ${GCE} == 'true' ]; then
    BWLIMIT=""
elif [ ${BWLIMITSET} != 'null' ]; then
    bc -l <<< "scale=2; ${BWLIMITSET}/${TRANSFERS}" >${PLEX_JSON}
    BWLIMITSPEED="$(cat ${PLEX_JSON})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
else
    BWLIMIT=""
    BWLIMITSPEED="no LIMIT was set"
fi
## bwlimitpart_function
touch "${LOGFILE}"
chmod 777 "${LOGFILE}"
#update json file for Uploader GUI
echo "{\"filedir\": \"${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"uploading\",\"logfile\": \"${LOGFILE}\",\"gdsa\": \"${GDSA}\"}" >"${JSONFILE}"
log "[Upload] Starting Upload"
rclone moveto --tpslimit 6 --checkers=${CHECKERS} \
       --config /config/rclone-docker.conf \
       --log-file="${LOGFILE}" --log-level INFO --stats 2s \
       --drive-chunk-size=${CHUNK}M ${BWLIMIT} \
       "${FILE}" "${REMOTE}:${FILEDIR}/${FILEBASE}"
ENDTIME=$(date +%s)
if [ "${RC_ENABLED}" == "true" ]; then
    sleep 10s
    rclone rc vfs/forget dir="${FILEDIR}" --user "${RC_USER:-user}" --pass "${RC_PASS:-xxx}" --no-output
fi
#update json file for Uploader GUI
echo "{\"filedir\": \"/${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"done\",\"gdsa\": \"${GDSA}\",\"starttime\": \"${STARTTIME}\",\"endtime\": \"${ENDTIME}\"}" >"${JSONFILE}"
### send note to discord 
discord_send_note
### send note to discord
log "[Upload] Upload complete for $FILE, Cleaning up"
#remove file lock
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
 sleep 5
 remove_left_over
 rm -f "${JSONFILE}"
else
 sleep 5
 remove_left_over
 sleep "${LOGHOLDUI}"
 rm -f "${JSONFILE}"
fi
