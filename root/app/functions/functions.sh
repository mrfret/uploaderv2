#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob || tHaTer || buGGprint
# All rights reserved.
## function source
function log() {
    echo "[Uploader] ${1}"
}
source /config/env/uploader.env
function base_folder_tdrive() {
mkdir -p /config/{pid,json,logs,vars,discord,env}
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
find /mnt/downloads -type f -name '*.lck' -delete
log "Cleaned up - Sleeping 10 secs"
sleep 10
}
function bc_start_up_test() {
# Check if BC is installed
BCTEST=/usr/bin/bc
if [ ! -f ${BCTEST} ]; then
   apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq
   apk add bc -qq
   rm -rf /var/cache/apk/*
   log "BC reinstalled"
   if [ "$(echo "10 + 10" | bc)" != "20" ]; then
      log " -> [ WARNING ] BC install  failed [ WARNING ] <-"
      sleep 30
      exit 1
   fi
fi
}
function rclone_update() {
log "-> update rclone || start <-"
    apk add unzip --quiet
    curl --no-progress-meter https://rclone.org/install.sh | bash -s beta >/dev/null 2>&1
if [[ $(command -v rclone | wc -l) == "1" ]]; then
    chown -cf abc:abc /root
fi
log "-> update rclone || done <-"
}
function update() {
log "-> update packages || start <-"
    apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
}
function discord_start_send_tdrive() {
source /config/env/uploader.env
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
   echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nTransfers is set to ${TRANSFERS}" >"${DISCORD}"
   msg_content=$(cat "${DISCORD}")
   if [ "${ENCRYPTED}" == "false" ]; then
      TITEL="Start of TDrive Uploader"
   else
      TITEL="Start of TCrypt Uploader"
   fi
   curl -sH "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
else
   log "Upload Docker is Starting"
   log "Started for the First Time - Cleaning up if from reboot"
   log "Uploads is based of ${BWLIMITSET}"
fi
}
#<|EOF|>#
