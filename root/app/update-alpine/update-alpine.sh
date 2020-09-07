#!/usr/bin/with-contenv bash
# shellcheck shell=bash
log "-> update rclone || start <-"
    apk add unzip --quiet
    curl --no-progress-meter https://rclone.org/install.sh | bash -s beta >/dev/null 2>&1
log "-> update rclone || done <-"

log "-> update packages || start <-"
    apk --no-cache update --quiet && apk --no-cache upgrade --quiet && apk --no-cache fix --quiet
    apk del --quiet --clean-protected --no-progress
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
#<EOF>#