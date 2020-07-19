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
###execute part 
SVLOG="serverside"
RCLONEDOCKER="/config/rclone-docker.conf"
LOGFILE="/config/logs/${SVLOG}.log"
truncate -s 0 /config/logs/${SVLOG}.log
sunday=$(date '+%A')
yanow="Sunday"
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
if grep -q "\[tcrypt\]" ${RCLONEDOCKER} && grep -q "\[gcrypt\]" ${RCLONEDOCKER}; then
    rccommand1=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 1 | tail -n 1))
    rccommand2=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 2 | tail -n 1))
    rccommand3=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 1 | tail -n 1))
    rccommand4=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 2 | tail -n 1))
   if [[ "${rccommand1}" != "${rccommand2}" && "${rccommand3}" != "${rccommand4}" ]]; then
      log " -->> Server_side can't be used <<-- "
      log " -->> TCrypt and GCrypt dont used the same password <<-- "
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
 if grep -q "\[tdrive\]" ${RCLONEDOCKER} ; then
    REMOTEDRIVE=tdrive
 else 
    exit 1
 fi
fi
#####
if [[ "${SERVERSIDEDRIVE}" == "null" ]]; then
 if grep -q "\[gdrive\]" ${RCLONEDOCKER} ; then
    SERVERSIDEDRIVE=gdrive
 else
    exit 1
 fi
fi
#####
### SERVERSIDE
#####
  if [[ ${sunday} != Sunday ]]; then
     sleep 10
  else
     if [ ${SERVERSIDE} == true ]; then
         echo "lock" >/config/json/serverside.lck
         echo "lock" >"${DISCORD}"
         STARTTIME=$(date +now)
         log "Starting Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
         rclone move --checkers 4 --transfers 2 \
                --config=${RCLONEDOCKER} --log-file="${LOGFILE}" --log-level INFO --stats 5s \
                --no-traverse ${SERVERSIDEAGE} --fast-list \
                "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
          sleep 5
          ENDTIME=$(date +now)
          if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
             TITEL="Server-Side Move"
             DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}              
             DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
             # shellcheck disable=SC2006 
             echo "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE} \nStarted : ${STARTTIME} \nFinished : ${ENDTIME}" >"${DISCORD}"
             msg_content=$(cat "${DISCORD}")
             curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
             rm -f ${DISCORD}
             rm -f /config/json/serverside.lck
          else
             log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
             rm -f /config/json/serverside.lck
          fi
      fi
  fi
