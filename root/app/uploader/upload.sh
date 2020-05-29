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
JSONFILE="/config/json/${FILEBASE}.json"
DISCORD="/config/discord/${FILEBASE}.discord"
PID="/config/pid"
PLEX=${PLEX}
GCE=${GCE}
PLEX_PREFERENCE_FILE=${PLEX_PREFERENCE_FILE}
PLEX_SERVER_IP=${PLEX_SERVER_IP}
PLEX_SERVER_PORT=${PLEX_SERVER_PORT}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
LOGHOLDUI=${LOGHOLDUI}
CHECKERS="$((${UPLOADS}*2))"
plex_script_root_folder="/app/plex"
touch ${plex_script_root_folder}/bwlimit.plex
touch ${plex_script_root_folder}/plex.streams
chown -cR 1000:1000 ${plex_script_root_folder}
chmod -cR 777 ${plex_script_root_folder}
PLEX_TOKEN=$(cat "${PLEX_PREFERENCE_FILE}" | sed -e 's;^.* PlexOnlineToken=";;' | sed -e 's;".*$;;' | tail -1)
PLEX_PLAYS=$(curl --silent "http://${PLEX_SERVER_IP}:${PLEX_SERVER_PORT}/status/sessions" -H "X-Plex-Token: $PLEX_TOKEN" | xmllint --xpath 'string(//MediaContainer/@size)' -)
echo "${PLEX_PLAYS}" >${plex_script_root_folder}/plex.streams
if [ ${PLEX} == 'true' ]; then
   bc -l <<< "scale=0; ${BWLIMITSET}/(${PLEX_PLAYS}*1.25)" >${plex_script_root_folder}/bwlimit.plex
fi
# add to file lock to stop another process being spawned while file is moving
echo "lock" >"${FILE}.lck"
echo "lock" >"${DISCORD}"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
##bwlimitpart
BWLIMITFILE="/app/plex/bwlimit.plex"
if [ ${PLEX} == 'true' ]; then
    BWLIMITSPEED="$(cat ${BWLIMITFILE})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
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
    BWLIMITSPEED="no LIMIT was set"
fi
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
### send note to discod 
  if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
    TIME="$((count=${ENDTIME}-${STARTTIME}))"
    duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
    echo "Upload complete for \nFILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED} \nTime : ${duration}" >"${DISCORD}"
    message=$(cat "${DISCORD}")
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
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
 sleep 5
 rm -f "${FILE}.lck"
 rm -f "${LOGFILE}"
 rm -f "${PID}/${FILEBASE}.trans"
 rm -f "${DISCORD}"
 find "${downloadpath}" -mindepth 2 -type d -empty -delete
 rm -f "${JSONFILE}"
else
 sleep 5
 rm -f "${FILE}.lck"
 rm -f "${LOGFILE}"
 rm -f "${PID}/${FILEBASE}.trans"
 rm -f "${DISCORD}"
 find "${downloadpath}" -mindepth 2 -type d -empty -delete
 sleep "${LOGHOLDUI}"
 rm -f "${JSONFILE}"
fi
