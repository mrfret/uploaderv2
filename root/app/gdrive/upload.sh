#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
# Logging Function
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
BWLIMITFILE="/app/plex/bwlimit.plex"
JSONFILE="/config/json/${FILEBASE}.json"
PLEX=${PLEX}
GCE=${GCE}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
CHECKERS="$((${UPLOADS}*2))"
# add to file lock to stop another process being spawned while file is moving
echo "lock" >"${FILE}.lck"
echo "lock" >"${FILEBASE}.discord"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
##bwlimitpart
if [ ${PLEX} == 'true' ]; then
    BWLIMITSPEED="$(cat ${BWLIMITFILE})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}"
elif [ ${GCE} == 'true' ]; then
    UPLOADS=${UPLOADS}
    BWLIMIT=""
elif [ ${BWLIMITSET} != 'null' ]; then
    UPLOADS=${UPLOADS}
    BWLIMITSET=${BWLIMITSET}
    BWLIMITSPEED="$((${BWLIMITSET}/${UPLOADS}))"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
else
    BWLIMIT=""
fi
#create and chmod the log file so that webui can read it
touch "${LOGFILE}"
chmod 777 "${LOGFILE}"
#update json file for Uploader GUI
echo "{\"filedir\": \"${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"uploading\",\"logfile\": \"${LOGFILE}\",\"gdsa\": \"${GDSA}\"}" >"${JSONFILE}"
log "[Upload] Starting Upload"
rclone moveto --tpslimit 6 --checkers=${CHECKERS} \
    --config /config/rclone-docker.conf \
    --log-file="${LOGFILE}" --log-level INFO --stats 2s \
    --drive-chunk-size=${CHUNK}M ${BWLIMIT} \
    --drive-stop-on-upload-limit \
    "${FILE}" "${REMOTE}:${FILEDIR}/${FILEBASE}"
ENDTIME=$(date +%s)
if [ "${RC_ENABLED}" == "true" ]; then
    sleep 10s
    rclone rc vfs/forget dir="${FILEDIR}" --user "${RC_USER:-user}" --pass "${RC_PASS:-xxx}" --no-output
fi
#update json file for Uploader GUI
echo "{\"filedir\": \"/${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"done\",\"gdsa\": \"${GDSA}\",\"starttime\": \"${STARTTIME}\",\"endtime\": \"${ENDTIME}\"}" >"${JSONFILE}"
### send note to discod 
  if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
    log "Upload complete for ${FILEDIR}/${FILEBASE} | SIZE : ${HRFILESIZE} | Speed : ${BWLIMIT}" >"${FILEBASE}.discord"
    message=$(cat ${FILEBASE}.discord)
    msg_content=\"$message\"
    USERNAME=\"${DISCORD_NAME_OVERRIDE}\"
    IMAGE=\"${DISCORD_ICON_OVERRIDE}\"
    DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL}"
    curl -H "Content-Type: application/json" -X POST -d "{\"username\": $USERNAME, \"avatar_url\": $IMAGE, \"content\": $msg_content}" $DISCORD_WEBHOOK_URL
  else
    log "[Upload] Upload complete for $FILE, Cleaning up"
  fi
#cleanup
#remove file lock
sleep 10
rm -f "${FILE}.lck"
rm -f "${LOGFILE}"
rm -f "/config/pid/${FILEBASE}.trans"
rm -f "${FILEBASE}.discord"
find "${downloadpath}" -mindepth 2 -type d -empty -delete
rm -f "${JSONFILE}"
sleep 10