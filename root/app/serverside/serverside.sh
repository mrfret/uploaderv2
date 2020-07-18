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

if pidof -o %PPID -x "$0"; then
    exit 1
fi

SVLOG="serverside"
RCLONEDOCKER="/config/rclone-docker.conf"
LOGFILE="/config/logs/${SVLOG}.log"
truncate -s 0 /config/logs/${SVLOG}.log
sunday="(date '+%A')"
yanow="Sunday"
PID="/config/pid"
echo "lock" >"${DISCORD}"
DISCORD="/config/discord/${SVLOG}.discord"
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
#####
SERVERSIDEDRIVE=${SERVERSIDEDRIVE:-null}
SERVERSIDE=${SERVERSIDE:-null}
REMOTEDRIVE=${REMOTEDRIVE:-null}
SERVERSIDEMINAGE=${SERVERSIDEMINAGE:-null}
#####
if [[ "${SERVERSIDE}" == "null" ]]; then
 if grep -q server_side** ${RCLONEDOCKER} ; then
    SERVERSIDE=true
 else 
   exit 1
 fi
fi
#####
if [ "${SERVERSIDEMINAGE}" != 'null' ]; then
   SERVERSIDEMINAGE=${SERVERSIDEMINAGE}
   SERVERSIDEAGE="--min-age ${SERVERSIDEMINAGE}"
else
   SERVERSIDEAGE="--min-age 48h"
fi
#####
if [[ "${REMOTEDRIVE}" == "null" ]]; then
 if [[ "$(grep -r tdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    REMOTEDRIVE=tdrive
 else 
    exit 1
 fi
fi
#####
if [[ "${SERVERSIDEDRIVE}" == "null" ]]; then
 if [[ "$(grep -r gdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    SERVERSIDEDRIVE=gdrive
 else
    exit 1
 fi
fi
#####
### SERVERSIDE
#####
# Run Loop
while true; do
  if [[ ${sunday} == Sunday ]]; then
     sleep 5
     if [ ${SERVERSIDE} == "true" ]; then
         echo "${SVLOG}" > "/config/pid/${SVLOG}.serverside" 
         echo "${SVLOG}" > "/config/pid/${SVLOG}.lck"
         STARTTIME=$(date +now)
         log "Starting Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
         rclone move --checkers 4 --transfers 2 \
                --config=${RCLONEDOCKER} --log-file="${LOGFILE}" --log-level INFO --stats 5s \
                --no-traverse ${SERVERSIDEAGE} --fast-list --delete-empty-src-dirs \
                "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
          sleep 5
          ENDTIME=$(date +now)
          if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
             TITEL="Server-Side Move"
             DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}              
             DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
             # shellcheck disable=SC2006 
             echo "log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE} \nStarted : ${STARTTIME} \nFinished : ${ENDTIME}" >"${DISCORD}"
             msg_content=$(cat "${DISCORD}")
             curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
          else
             log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
          fi
    else
     log "Next Start on ${yanow}"
     log "Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
        if [[ ${sunday} != Sunday ]]; then
            sleep 24h || break
        fi
  fi
  rm -f "${PID}/${SVLOG}.lck" \
       "${LOGFILE}" \
       "${PID}/${SVLOG}.serverside" \
       "${DISCORD}"
done
