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
function serverside() {
sunday=$(date '+%A')
SERVERSIDE=${SERVERSIDE}
lock=/config/json/serverside.lck
if [[ "${SERVERSIDE}" != "false" && ${sunday} == Sunday ]]; then
   if [[ ! -f ${lock} ]]; then 
      serverside_command
   else 
      sleep 10
   fi
fi
}
function serverside_command() {
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
SERVERSIDE=${SERVERSIDE}
REMOTEDRIVE=${REMOTEDRIVE:-null}
SERVERSIDEMINAGE=${SERVERSIDEMINAGE:-null}
SERVERSIDECHECK=$(cat ${RCLONEDOCKER} | awk '$1 == "server_side_across_configs" {print $3}' | wc -l)
#####

if [[ "${SERVERSIDECHECK}" -lt "2" ]]; then
   log ">>>> [ WARNING ] Server-Side failed [ WARNING ] <<<<<"
   log ">>>> [ WARNING ] check your rclone-docker.conf [ WARNING ] <<<<<"
   sleep 10
   exit 1
fi

if grep -q "\[tcrypt\]" ${RCLONEDOCKER} && grep -q "\[gcrypt\]" ${RCLONEDOCKER}; then
    rccommand1=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 1 | tail -n 1))
    rccommand2=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 2 | tail -n 1))
    rccommand3=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 1 | tail -n 1))
    rccommand4=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 2 | tail -n 1))
   if [[ "${rccommand1}" != "${rccommand2}" && "${rccommand3}" != "${rccommand4}" ]]; then
      log ">>>>> [ WARNING ] Server_side can't be used <<<<< [ WARNING ]"
      log ">>>>> [ WARNING ] TCrypt and GCrypt dont used the same password <<<<< [ WARNING ]"
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
lock=/config/json/serverside.lck
if [[ ! -e ${lock} ]]; then
   echo "lock" >${lock}
   echo "lock" >"${DISCORD}"
   STARTTIME=$(date +%s)
   log "Starting Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
   rclone move --checkers 4 --transfers 2 \
          --config=${RCLONEDOCKER} --log-file="${LOGFILE}" --log-level INFO --stats 5s \
          --no-traverse ${SERVERSIDEAGE} --fast-list \
          "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
   sleep 5
   ENDTIME=$(date +%s)
   if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
      TITEL="Server-Side Move"
      DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}              
      DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
      TIME="$((count=${ENDTIME}-${STARTTIME}))"
      duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
      # shellcheck disable=SC2006 
      echo "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE} \nTime : ${duration}" >"${DISCORD}"
      msg_content=$(cat "${DISCORD}")
      curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE}\", \"embeds\": [{ \"title\": \"${TITEL}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL
      rm -rf "${DISCORD}" /
            "${lock}"
   else
      log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
      rm -rf "${lock}"
      fi
else
  sleep 24h
fi
}

serverside
