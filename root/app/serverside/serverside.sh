#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020 ; MrDoob
# All rights reserved.
# SERVER SIDE ACTION 
##############################
####
function log() {
    echo "[Server Side] ${1}"
}

SVLOG="serverside"
RCLONEDOCKER="/config/rclone-docker.conf"
LOGFILE="/config/logs/${SVLOG}.log"
truncate -s 0 /config/logs/${SVLOG}.log
#####
SERVERSIDE=${SERVERSIDE:-false}
if [[ "${SERVERSIDE}" == "false" ]]; then
 if grep -q server_side** ${RCLONEDOCKER} ; then
    SERVERSIDE=true
 else 
   exit 1
 fi
fi
#####
if [ "${SERVERSIDEMINAGE}" != 'null' ]; then
   SERVERSIDEMINAGE=${SERVERSIDEMINAGE}
   SERVERSIDEAGE="--min-age=${SERVERSIDEMINAGE}"
else
   SERVERSIDEAGE="--min-age=48h"
fi
#####
REMOTEDRIVE=${REMOTEDRIVE:-false}
if [[ "${REMOTEDRIVE}" == "false" ]]; then
 if [[ "$(grep -r tdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    REMOTEDRIVE=tdrive
 else 
    exit 1
 fi
fi
#####
SERVERSIDEDRIVE=${SERVERSIDEDRIVE:-false}
if [[ "${SERVERSIDEDRIVE}" == "false" ]]; then
 if [[ "$(grep -r gdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    SERVERSIDEDRIVE=gdrive
 else
    exit 1
 fi
fi
sunday="(date '+%A')"
yanow="Sunday"

#####
### SERVERSIDE
#####
# Run Loop
while true; do
  if [[ ${sunday} == Sunday ]]; then
     continue
     if [ ${SERVERSIDE} == "true" ]; then
         log "Starting Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
         rclone move --checkers 4 --transfers 2 \
                --config=${RCLONEDOCKER} --log-file="${LOGFILE}" --log-level INFO --stats 5s \
                --no-traverse ${SERVERSIDEAGE} --fast-list \
                "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
         log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
     fi
  else
     log "Next Start on ${yanow}"
     log "Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
        if [[ ${sunday} != Sunday ]]; then
            break
        fi
  fi 
done
