#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
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
PID="/config/pid"
PLEX=${PLEX:-false}
test_2=$(ls -la /config  | grep -c xml)
test_1=$(ls -la /app  | grep -c xml)
if [ ${PLEX} == "false" ]; then
  if [[ ${test_1} == "1"  || ${test_2} == "1" ]]; then
    PLEX=true
  fi
fi
BWLIMITSET=${BWLIMITSET}
if [ "${BWLIMITSET}" == 'null' ]; then
    BWLIMITSET=100
else
   BWLIMITSET=${BWLIMITSET}
fi
GCE=${GCE:-false}
if [ "${GCE}" == "false" ]; then
gcheck=$(dnsdomainname | tail -c 10)
 if [ "$gcheck" == ".internal" ]; then
    GCE=true
 fi
fi
# TITEL=${DISCORD_EMBED_TITEL}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
LOGHOLDUI=${LOGHOLDUI}
TRANSFERS=$(ls -la /config/pid/ | grep -c trans)
CHECKERS="$((${TRANSFERS}*2))"
PLEX_JSON="/config/json/${FILEBASE}.bwlimit"
##### BWLIMIT-PART
if [[ ${PLEX} == "true" || ${BWLIMITSET} != "null" ]]; then
   VNSTAT_JSON="/config/json/${FILEBASE}.monitor"
   vnstat -i eth0 -tr 8 | awk '$1 == "tx" {print $2}' | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/' > ${VNSTAT_JSON}
   bc <<< "scale=3; ${BWLIMITSET} - $(cat ${VNSTAT_JSON})" >${PLEX_JSON}
fi
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
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
if [[ ${PLEX} == "true" || ${BWLIMITSET} != "null" ]]; then
     if [ ${TRANSFERS} -le "2" ]; then 
         BWLIMITSPEED="$(echo $(( ((${BWLIMITSET}-${TRANSFERS}))/10*5 | bc )) | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')"
         ####BWLIMITSPEED="35"        
         BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
      else
         BWLIMITSPEED="$(cat /config/json/${FILEBASE}.bwlimit)"
         BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
     fi
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
   TITEL=${DISCORD_EMBED_TITEL}
   DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
   DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
 # shellcheck disable=SC2003
  TIME="$((count=${ENDTIME}-${STARTTIME}))"
  duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
  echo "FILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED}M \nTime : ${duration} \nActive Transfers : ${TRANSFERS}" >"${DISCORD}"
  msg_content=$(cat "${DISCORD}")
  curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
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
       "${VNSTAT_JSON}"
 find "${downloadpath}" -mindepth 1 -type d ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -empty -exec rmdir \{} \; 1>/dev/null 2>&1
 rm -f "${JSONFILE}"
else
 sleep 1
 rm -f "${FILE}.lck" \
       "${PLEX_JSON}" \
       "${PLEX_STREAMS}" \
       "${LOGFILE}" \
       "${PID}/${FILEBASE}.trans" \
       "${DISCORD}" \
       "${VNSTAT_JSON}"
 find "${downloadpath}" -mindepth 1 -type d ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -empty -exec rmdir \{} \; 1>/dev/null 2>&1
 sleep "${LOGHOLDUI}"
 rm -f "${JSONFILE}"
fi
