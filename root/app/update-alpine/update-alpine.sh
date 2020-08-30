#!/usr/bin/with-contenv bash
# shellcheck shell=bash
log "-> update rclone || start <-"
    wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
    unzip -qq rclone.zip && rm rclone.zip && \
    mv rclone*/rclone /usr/bin && rm -rf rclone* 
log "-> update rclone || done <-"

log "-> update packages || start <-"
    apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
#<EOF>#