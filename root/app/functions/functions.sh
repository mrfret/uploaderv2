#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob || tHateS || tRiGG3R
# All rights reserved.
function log() {
    echo "[Uploader] ${1}"
}
function folders() {
#Make sure all the folders we need are created
mkdir -p /config/pid/
mkdir -p /config/json/
mkdir -p /config/logs/
mkdir -p /config/vars/
mkdir -p /config/discord/
}
function bc-test() {
# Check if BC is installed
if [ "$(echo "10 + 10" | bc)" == "20" ]; then
    log "BC Found! All good :)"
else
    log "BC Not installed, Exit"
    exit 2
fi
}
function cleanup() {
# Remove left over webui and transfer files
rm -f /config/pid/*
rm -f /config/json/*
rm -f /config/logs/*
rm -f /config/discord/*
# delete any lock files for files that failed to upload
find ${downloadpath} -type f -name '*.lck' -delete
log "Cleaned up - Sleeping 10 secs"
sleep 10
}
function ignore_files() {
HOLDFILESONDRIVE=${HOLDFILESONDRIVE}
if [ "${HOLDFILESONDRIVE}" == 'null' ]; then
   HOLDFILESONDRIVE="5"
fi
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi
find ${downloadpath} -type f -mmin +${HOLDFILESONDRIVE} ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} | sort -k1
}
function gdrive-discord_send_note() {
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is set to ${UPLOADS}\nUpload Delay is set to ${HOLDFILESONDRIVE} min" >"${DISCORD}"
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
  log "Upload Delay is set to ${HOLDFILESONDRIVE} min"
fi
}

function tdrive-discord_send_note() {
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is set to ${UPLOADS}\nUpload Delay is set to ${HOLDFILESONDRIVE} min" >"${DISCORD}"
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
  log "Upload Delay is set to ${HOLDFILESONDRIVE} min"
fi
}
function remove_left_over() {
LOGHOLDUI=${LOGHOLDUI}
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi
 rm -f "${FILE}.lck"
 rm -f "${PLEX_JSON}"
 rm -f "${PLEX_STREAMS}"
 rm -f "${LOGFILE}"
 rm -f "${PID}/${FILEBASE}.trans"
 rm -f "${DISCORD}"
 find "${downloadpath}" -mindepth 1 -type d ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -empty -delete
}
function discord_send_note() {
TITEL=${DISCORD_EMBED_TITEL}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
 # shellcheck disable=SC2003
  TIME="$((count=${ENDTIME}-${STARTTIME}))"
  duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
  echo "Upload complete for \nFILE: GSUITE/${FILEDIR}/${FILEBASE} \nSIZE : ${HRFILESIZE} \nSpeed : ${BWLIMITSPEED} \nTime : ${duration}" >"${DISCORD}"
  msg_content=$(cat "${DISCORD}")
  curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
fi
}
function plex_process() {
PLEX_PREFERENCE_FILE="/config/plex/docker-preferences.xml"
PLEX_SERVER_IP=${PLEX_SERVER_IP}
PLEX_SERVER_PORT=${PLEX_SERVER_PORT}
PLEX=${PLEX}
# PLEX_STREAMS="/config/json/${FILEBASE}.streams"
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
}
