#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob || tHaTer || buGGprint
# All rights reserved.
## function source

function log() {
    echo "[Uploader] ${1}"
}

function base_folder_gdrive() {
mkdir -p /config/pid/ \
         /config/json/ \
         /config/logs/ \
         /config/vars/ \
         /config/discord/ \
         /config/vars/gdrive/
}

function base_folder_tdrive() {
mkdir -p /config/pid/ \
         /config/json/ \
         /config/logs/ \
         /config/vars/ \
         /config/discord/
}

function remove_old_files_start_up() {
# Remove left over webui and transfer files
rm -f /config/pid/* \
      /config/json/* \
      /config/logs/* \
      /config/discord/*
}

function cleanup_start() {
# delete any lock files for files that failed to upload
find ${downloadpath} -type f -name '*.lck' -delete
log "Cleaned up - Sleeping 10 secs"
sleep 10
}

function bc_start_up_test() {
# Check if BC is installed
if [ "$(echo "10 + 10" | bc)" == "20" ]; then
    log "BC Found! All good :)"
else
    apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq && apk add bc -qq
    rm -rf /var/cache/apk/*
    log "BC reinstalled, Exit"
fi
}
function rclone() {
log "-> update rclone || start <-"
      wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
      unzip -qq rclone.zip && rm rclone.zip && \
      mv rclone*/rclone /usr/bin && rm -rf rclone* 
log "-> update rclone || done <-"
}
function update() {
log "-> update packages || start <-"
      apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq
      rm -rf /var/cache/apk/*
log "-> update packages || done <-"
}

function discord_start_send_gdrive() {
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is set to ${UPLOADS}" >"${DISCORD}"
  msg_content=$(cat "${DISCORD}")
  if [[ "${ENCRYPTED}" == "false" ]]; then
    TITEL="Start of GDrive Uploader"
  else
    TITEL="Start of GCrypt Uploader"
  fi
  curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
else
  log "Upload Docker is Starting"
  log "Started for the First Time - Cleaning up if from reboot"
  log "Uploads is set to ${UPLOADS}"
fi
}

function discord_start_send_tdrive() {
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is set to ${UPLOADS}" >"${DISCORD}"
  msg_content=$(cat "${DISCORD}")
  if [[ "${ENCRYPTED}" == "false" ]]; then
    TITEL="Start of TDrive Uploader"
  else
    TITEL="Start of TCrypt Uploader"
  fi
  curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
else
  log "Upload Docker is Starting"
  log "Started for the First Time - Cleaning up if from reboot"
  log "Uploads is set to ${UPLOADS}"
fi
}

function bwlimitpart() {
IFS=$'\n'
FILE=$1
FILEBASE=$(basename "${FILE}")
PLEX=${PLEX}
GCE=${GCE}
BWLIMITSET=${BWLIMITSET}
UPLOADS=${UPLOADS}
PLEX_PREFERENCE_FILE="/config/plex/docker-preferences.xml"
PLEX_SERVER_IP=${PLEX_SERVER_IP}
PLEX_SERVER_PORT=${PLEX_SERVER_PORT}
PLEX_JSON="/config/json/${FILEBASE}.bwlimit"
PLEX_STREAMS="/config/json/${FILEBASE}.streams"
TRANSFERS=$(ls -la /config/pid/ | grep -c trans)
PLEX_TOKEN=$(cat "${PLEX_PREFERENCE_FILE}" | sed -e 's;^.* PlexOnlineToken=";;' | sed -e 's;".*$;;' | tail -1)
PLEX_PLAYS=$(curl --silent "http://${PLEX_SERVER_IP}:${PLEX_SERVER_PORT}/status/sessions" -H "X-Plex-Token: $PLEX_TOKEN" | xmllint --xpath 'string(//MediaContainer/@size)' -)
PLEX_SELFTEST=$(curl -LI "http://${PLEX_SERVER_IP}:${PLEX_SERVER_PORT}/system?X-Plex-Token=${PLEX_TOKEN}" -o /dev/null -w '%{http_code}\n' -s)
echo "${PLEX_PLAYS}" >${PLEX_STREAMS}
if [ "${PLEX}" == "true" ]; then
  if [[ ${PLEX_SELFTEST} -ge "200" && ${PLEX_SELFTEST} -lt "299" ]]; then
    # shellcheck disable=SC2086
	if [[ ${PLEX_PLAYS} == "0" || ${UPLOADS} -le ${TRANSFERS} ]]; then
     bc -l <<< "scale=2; ${BWLIMITSET}/${TRANSFERS}" >${PLEX_JSON}
    elif [[ ${PLEX_PLAYS} -ge "0" && ${PLEX_PLAYS} -le ${UPLOADS} ]]; then
      bc -l <<< "scale=2; ${BWLIMITSET}/${PLEX_PLAYS}" >${PLEX_JSON}
    elif [ ${PLEX_PLAYS} -ge ${UPLOADS} ]; then
      bc -l <<< "scale=2; ${BWLIMITSET}/${PLEX_PLAYS}" >${PLEX_JSON}
    else
      bc -l <<< "scale=2; ${BWLIMITSET}/${TRANSFERS}" >${PLEX_JSON}
    fi
  else
    bc -l <<< "scale=2; ${BWLIMITSET}/${TRANSFERS}" >${PLEX_JSON}
  fi
fi

##bwlimitpart
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
}

function uploader() {
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
TITEL=${DISCORD_EMBED_TITEL}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
LOGHOLDUI=${LOGHOLDUI}
CHECKERS="$((${UPLOADS}*2))"
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi
echo "lock" >"${FILE}.lck"
echo "lock" >"${DISCORD}"
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
bwlimitpart
BWLIMIT=${BWLIMIT}
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
 # shellcheck disable=SC2003
  TIME="$((count=${ENDTIME}-${STARTTIME}))"
  duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
if [ ${PLEX} == 'true' ]; then
  echo "FILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED}M \nTime : ${duration} \nActive Transfers : ${TRANSFERS} \nActive Plex Streams : ${PLEX_PLAYS}" >"${DISCORD}"
elif [ ${GCE} == 'true' ]; then
  echo "FILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : GCE-MODE is running \nTime : ${duration} \nActive Transfers : ${TRANSFERS}" >"${DISCORD}"
else
  echo "FILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED}M \nTime : ${duration} \nActive Transfers : ${TRANSFERS}" >"${DISCORD}"
fi
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
       "${DISCORD}"
 find "${downloadpath}" -mindepth 1 -type d ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -empty -delete 1>/dev/null 2>&1
 rm -f "${JSONFILE}"
else
 sleep 1
 rm -f "${FILE}.lck" \
       "${PLEX_JSON}" \
       "${PLEX_STREAMS}" \
       "${LOGFILE}" \
       "${PID}/${FILEBASE}.trans" \
       "${DISCORD}"
 find "${downloadpath}" -mindepth 1 -type d ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -empty -delete 1>/dev/null 2>&1
 sleep "${LOGHOLDUI}"
 rm -f "${JSONFILE}"
fi