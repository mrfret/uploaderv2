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

getenvs

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

getenvs

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

function getenvs() {
UPLOADS=${UPLOADS}
if [ "${UPLOADS}" == '' ]; then
   UPLOADS=${UPLOADS:-4}
else
   UPLOADS=${UPLOADS}
fi
###
BWLIMITSET=${BWLIMITSET}
if [ "${BWLIMITSET}" == '' ]; then
   BWLIMITSET=${BWLIMITSET:-80}
else
   BWLIMITSET=${BWLIMITSET}
fi
###
CHUNK=${CHUNK}
if [ "${CHUNK}" == '' ]; then
   CHUNK=${CHUNK:-32}
else
   CHUNK=${CHUNK}
fi
###
TZ=${TZ}
if [ "${TZ}" == '' ]; then
   TZ=${TZ:-UTC}
else
   TZ=${TZ}
fi
###
LOGHOLDUI=${LOGHOLDUI}
if [ "${LOGHOLDUI}" == '' ]; then
   LOGHOLDUI=${LOGHOLDUI:-5m}
else
   LOGHOLDUI=${LOGHOLDUI}
fi
###
PLEX_FILE=/config/plex/docker-preferences.xml
GCECHECK=$(dnsdomainname | tail -c 10)
if [ -f ${PLEX_FILE} ]; then
  PLEX=${PLEX:-true}
  PLEX_SERVER_IP=${PLEX_SERVER_IP:-plex}
  PLEX_SERVER_PORT=${PLEX_SERVER_PORT:-32400}
  GCE=${GCE:-false}
 elif [ "$gcheck" == ".internal" ]; then
  PLEX=${PLEX:-false}
  GCE=${GCE:-true}
 else
  PLEX=${PLEX:-false}
  GCE=${GCE:-false}
  LOGHOLDUI=${LOGHOLDUI:-5m}
fi

DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}

if [ "${DISCORD_WEBHOOK_URL}" == 'null' ]; then 
  LOGHOLDUI=${LOGHOLDUI:-5m}
 else
  DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE:-https://i.imgur.com/MZYwA1I.png}
  DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE:-RCLONE}
  DISCORD_EMBED_TITEL=${DISCORD_EMBED_TITEL:-Upload_Completed}
fi
}