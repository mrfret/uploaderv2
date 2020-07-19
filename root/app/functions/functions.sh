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
BWLIMITSET=${BWLIMITSET:-80}
if [[ ${BWLIMITSET} == "" ]]; then
    BWLIMITSET=100
else
   BWLIMITSET=${BWLIMITSET}
fi
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is based of ${BWLIMITSET}M" >"${DISCORD}"
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
  log "Uploads is based of ${BWLIMITSET}"
fi
}

function discord_start_send_tdrive() {
BWLIMITSET=${BWLIMITSET:-80}
if [[ ${BWLIMITSET} == "" ]]; then
    BWLIMITSET=100
else
   BWLIMITSET=${BWLIMITSET}
fi
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is based of ${BWLIMITSET}M" >"${DISCORD}"
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
  log "Uploads is based of ${BWLIMITSET}"
fi
}

function empty_folder() {
find /move -mindepth 1 -type d -empty -delete 
}

function serverside() {
sunday=$(date '+%A')
###lock="/config/json/serverside.lck"
    if [[ ${sunday} == Sunday ]]; then
       if [[ -e "/config/json/serverside.lck" ]]; then
           sleep 30
       else 
           /app/serverside/serverside.sh &
           sleep 30
       fi
    else 
        sleep 30
    fi
}
