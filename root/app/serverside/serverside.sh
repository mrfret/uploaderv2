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
source /config/env/serverside.env
source /app/functions/functions.sh
###execute part 
SVLOG="serverside"
RCLONEDOCKER="/config/rclone/rclone-docker.conf"
LOGFILE="/config/logs/serverside.log"
if [[ -f ${LOGFILE} ]]; then
   truncate -s 0 ${LOGFILE}
fi
DISCORD="/config/discord/${SVLOG}.discord"
SERVERSIDECHECK=$(cat ${RCLONEDOCKER} | awk '$1 == "server_side_across_configs" {print $3}' | wc -l)
LOCK=/config/json/serverside.lck
#####
if [ -e ${LOCK} ]; then
    rm -rf ${LOCK}
fi
#####
if [[ "${SERVERSIDE}" != 'true' ]]; then
   sleep $(($(date -f - +%s- <<< $'tomorrow 00:30\nnow')0))
   exit 0
fi
#####
if [[ ${SERVERSIDECHECK} -le "1" && ${SERVERSIDE} == 'true' ]]; then
   if [ "${SERVERSIDE}" != 'false' ] || [ "${SERVERSIDE}" != 'down' ]; then
      sed -i '/type = drive/a\server_side_across_configs = true' ${RCLONEDOCKER}
   fi
fi
sleep 5
####
if [ "${SERVERSIDECHECK}" -gt "1" ]; then
   log ">>>>> [ SERVERSIDE ] ------------------------------------- <<<<< [ SERVERSIDE ]"
   log ">>>>> [ SERVERSIDE ]         Server-Side works             <<<<< [ SERVERSIDE ]"
   log ">>>>> [ SERVERSIDE ] ------------------------------------- <<<<< [ SERVERSIDE ]"
else
   log ">>>>> [ WARNING ] ------------------------------------- <<<<< [ WARNING ]"
   log ">>>>> [ WARNING ]         Server-Side failed            <<<<< [ WARNING ]"
   log ">>>>> [ WARNING ]     check your rclone-docker.conf     <<<<< [ WARNING ]"
   log ">>>>> [ WARNING ] ------------------------------------- <<<<< [ WARNING ]"
   sleep 60
   exit 0
fi
####
if grep -q "\[tcrypt\]" ${RCLONEDOCKER} && grep -q "\[gcrypt\]" ${RCLONEDOCKER}; then
   rccommand1=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 1 | tail -n 1))
   rccommand2=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password" {print $3}' | head -n 2 | tail -n 1))
   rccommand3=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 1 | tail -n 1))
   rccommand4=$(rclone reveal $(cat ${RCLONEDOCKER} | awk '$1 == "password2" {print $3}' | head -n 2 | tail -n 1))
   if [[ "${rccommand1}" != "${rccommand2}" && "${rccommand3}" != "${rccommand4}" ]]; then
      log ">>>>> [ WARNING ] --------------------------------------------- <<<<< [ WARNING ]"
      log ">>>>> [ WARNING ]           Server_side can't be used           <<<<< [ WARNING ]"
      log ">>>>> [ WARNING ] TCrypt and GCrypt dont used the same password <<<<< [ WARNING ]"
      log ">>>>> [ WARNING ] --------------------------------------------- <<<<< [ WARNING ]"
      sleep 60
      exit 0
   fi
fi
#####
if [ "${SERVERSIDEMINAGE}" == 'null' ] || [ "${SERVERSIDEMINAGE}" == 'false' ]; then
   SERVERSIDEAGE="--min-age 48h"
else
   SERVERSIDEMINAGE=${SERVERSIDEMINAGE}
   SERVERSIDEAGE="--min-age ${SERVERSIDEMINAGE}"
fi
#####
if [[ "${REMOTEDRIVE}" == "null" ]]; then
   if grep -q "\[gdrive\]" ${RCLONEDOCKER} ; then
      REMOTEDRIVE=gdrive
   else
      sleep 60
      exit 0
   fi
else
   REMOTEDRIVE=${REMOTEDRIVE}
fi
#####
if [[ "${SERVERSIDEDRIVE}" == "null" ]]; then
   if grep -q "\[tdrive\]" ${RCLONEDOCKER} ; then
      SERVERSIDEDRIVE=tdrive
   else
      sleep 60
      exit 0
   fi
else
   SERVERSIDEDRIVE=${SERVERSIDEDRIVE}
fi
#####
if [[ "${SERVERSIDEDAY}" == 'null' ]]; then
   SERVERSIDEDAY=Sunday
 else
   SERVERSIDEDAY=${SERVERSIDEDAY}
fi
################
## SERVERSIDE ##
################
while true; do
   if [ $(date '+%A') == "${SERVERSIDEDAY}" ] || [ "${SERVERSIDEDAY}" == 'daily' ]; then
   SERVERSIDE=${SERVERSIDE}
   lock="/config/json/serverside.lck"
   RCLONEDOCKER="/config/rclone/rclone-docker.conf"
   REMOTEDRIVE=${REMOTEDRIVE}
   SERVERSIDEMINAGE=${SERVERSIDEMINAGE}
   SERVERSIDEDRIVE=${SERVERSIDEDRIVE}
   LOGFILE="/config/logs/serverside.log"
   echo "lock" >"${lock}"
   echo "lock" >"${DISCORD}"
   STARTTIME=$(date +%s)
   touch "${LOGFILE}"
   log "Starting Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
   rclone moveto --checkers 4 --transfers 2 --config=${RCLONEDOCKER} --user-agent=${UAGENT} \
                 --log-file="${LOGFILE}" --use-server-modtime --log-level INFO --stats 10s --no-traverse ${SERVERSIDEAGE} \
                 --exclude="**backup**"--exclude="**plexguide/**" \
                 "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
   ENDTIME=$(date +%s)
   if [ ${DISCORD_WEBHOOK_URL_SERVERSIDE} != 'null' ]; then
      DISCORD_EMBED_TITEL_SERVERSIDE=${DISCORD_EMBED_TITEL_SERVERSIDE}
      DISCORD_ICON_OVERRIDE_SERVERSIDE=${DISCORD_ICON_OVERRIDE_SERVERSIDE}              
      DISCORD_NAME_OVERRIDE_SERVERSIDE=${DISCORD_NAME_OVERRIDE_SERVERSIDE}
      TIME="$((count=${ENDTIME}-${STARTTIME}))"
      duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
      MOVEDFILES=$(cat ${LOGFILE} | grep "Renamed" | tail -n 1 | awk '{print $2}')
      # shellcheck disable=SC2006 
      echo "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE} \nMoved Files : ${MOVEDFILES} \nTime : ${duration}" >"${DISCORD}"
      msg_content=$(cat "${DISCORD}")
      curl -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DISCORD_NAME_OVERRIDE_SERVERSIDE}\", \"avatar_url\": \"${DISCORD_ICON_OVERRIDE_SERVERSIDE}\", \"embeds\": [{ \"title\": \"${DISCORD_EMBED_TITEL_SERVERSIDE}\", \"description\": \"$msg_content\" }]}" $DISCORD_WEBHOOK_URL_SERVERSIDE
      rm -rf "${DISCORD}"
      rm -rf "${lock}"
   else
      log "Finished Server-Side move from ${REMOTEDRIVE} to ${SERVERSIDEDRIVE}"
      rm -rf "${lock}"
   fi
   sleep 10 && sleep $(($(date -f - +%s- <<< $'tomorrow 00:30\nnow')0))
   else
     sleep $(($(date -f - +%s- <<< $'tomorrow 00:30\nnow')0))
   fi
done
#<EOF>#
