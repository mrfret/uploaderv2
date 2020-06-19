#!/usr/bin/with-contenv bash
# shellcheck shell=bash
function log() {
echo "[Uploader] ${1}"
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
rclone
update
