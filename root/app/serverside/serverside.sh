#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020 ; MrDoob
# All rights reserved.
# SERVER SIDE ACTION 
##############################
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
   SERVERSIDEAGE=""
fi
#####
REMOTEDRIVE=${REMOTEDRIVE:-false}
if [[ "${REMOTEDRIVE}" == "false" ]]; then
 if [[ "$(grep -r gdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    REMOTEDRIVE=gdrive
 else 
    exit 1
 fi
fi
#####
SERVERSIDEDRIVE=${SERVERSIDEDRIVE:-false}
if [[ "${SERVERSIDEDRIVE}" == "false" ]]; then
 if [[ "$(grep -r tdrive ${RCLONEDOCKER} | wc -l )" -gt 1 ]]; then
    SERVERSIDEDRIVE=tdrive
 else
    exit 1
 fi
fi
#####
### SERVERSIDE
#####
if [ "${SERVERSIDE}" == "true" ]; then
rclone move --checkers 4 --transfers 2 \
       --config=${RCLONEDOCKER} --log-file="${LOGFILE}" --log-level INFO --stats 5s \
       --no-traverse ${SERVERSIDEAGE} --fast-list \
        "${REMOTEDRIVE}:" "${SERVERSIDEDRIVE}:"
else
   exit 1
fi
