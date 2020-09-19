#!/usr/bin/with-contenv bash
# shellcheck shell=bash
function log() {
echo "[UPDATE] ${1}"
}
## function source start
log "-> update rclone || start <-"
apk add unzip bash curl --quiet
wget --quiet https://beta.rclone.org/rclone-beta-latest-linux-amd64.zip -O rclone.zip && \
unzip -q rclone.zip && rm rclone.zip && \
mv rclone*/rclone /usr/bin && rm -r rclone*
log "-> update rclone || done <-"

log "-> update packages || start <-"
    apk --no-cache update --quiet && apk --no-cache upgrade --quiet && apk --no-cache fix --quiet
    apk del --quiet --clean-protected --no-progress
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
#<EOF>#
