#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# Copyright (c) 2020 MrDoob
# All rights reserved.

# Logging Function
function log() {
    echo "[Uploader] ${1}"
}

#Make sure all the folders we need are created
path=/config/keys/
mkdir -p /config/{pid,json,logs,vars}
downloadpath=/mnt/downloads
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
    if grep -q GDSA01C /config/rclone/rclone-docker.conf && grep -q GDSA02C /config/rclone/rclone-docker.conf; then
       ENCRYPTED=true
    fi
fi
#Header
log "Uploader Started"
log "Started for the First Time - Cleaning up if from reboot"
# Remove left over webui and transfer files
rm -f /config/pid/*
rm -f /config/json/*
rm -f /config/logs/*
# delete any lock files for files that failed to upload
find ${downloadpath} -type f -name '*.lck' -delete
log "Cleaned up - Sleeping 10 secs"
sleep 10
#### Generates the GDSA List from the Processed Keys
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196
GDSAARRAY=(`ls -la ${path} | awk '{print $9}' | egrep '(PG|GD|GS)'`)
# shellcheck disable=SC2003
GDSACOUNT=$(expr ${#GDSAARRAY[@]} - 1)
# Check to see if we have any keys
# shellcheck disable=SC2086
if [ ${GDSACOUNT} -lt 1 ]; then
    log "No accounts found to upload with, Exit"
    exit 1
fi
# Check if BC is installed
if [ "$(echo "10 + 10" | bc)" == "20" ]; then
    log "BC Found! All good :)"
else
    log "BC Not installed, Exit"
    exit 2
fi

if [[ ! -f /config/vars/lastGDSA ]];then touch /config/vars/lastGDSA 1>/dev/null 2>&1;fi
if [[ ! -f /config/vars/gdsaAmount ]];then touch /config/vars/gdsaAmount 1>/dev/null 2>&1;fi
if [[ -d /config ]];then chown -cR abc:abc /config/vars/ 1>/dev/null 2>&1;fi

# Grabs vars from files
if [[ -e /config/vars/lastGDSA ]]; then
    GDSAUSE=$(cat /config/vars/lastGDSA)
    GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
    GDSAUSE=0
    GDSAAMOUNT=0
fi
#
BASICIGNORE="! -name '**.anchor' ! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '**.inProgress/**'"
DOWNLOADIGNORE="! -path '**.anchors/**' ! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**' ! -path '**-vpn/**' ! -path '**_UNPACK_**'"
#
# Run Loop
while true; do
    source /config/env/uploader.env
    if [[ ${ADDITIONAL_IGNORES} == 'null' ]];then ADDITIONAL_IGNORES="";fi
    #Find files to transfer
    IFS=$'\n'
    mapfile -t files < <(eval find ${downloadpath} -cmin +${MIN_AGE_UPLOAD} -type f ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES})
    if [[ ${#files[@]} -gt 0 ]]; then
        # If files are found loop though and upload
        log "Files found to upload"
        for i in "${files[@]}"; do
            FILEDIR=$(dirname "${i}" | sed "s#${downloadpath}${MOVE_BASE}##g")
            # If file has a lockfile skip
            if [ -e "${i}.lck" ]; then
                log "Lock File found for ${i}"
                continue
            else
                if [ -e "${i}" ]; then
                    # Check if file is still getting bigger
                    FILESIZE1=$(stat -c %s "${i}")
                    sleep 5
                    FILESIZE2=$(stat -c %s "${i}")
                    if [ "$FILESIZE1" -ne "$FILESIZE2" ]; then
                        log "File is still getting bigger ${i}"
                        continue
                    fi
                    # Check if we have any upload slots available
                    # shellcheck disable=SC2010
                    TRANSFERS=${TRANSFERS}
                    ACTIVETRANSFERS=$(ls -la /config/pid/ | grep -c trans)
                    # shellcheck disable=SC2086
                    if [ ! ${ACTIVETRANSFERS} -ge ${TRANSFERS} ]; then
                        if [ -e "${i}" ]; then
                            log "Starting upload of ${i}"
                            # Append filesize to GDSAAMOUNT
                            GDSAAMOUNT=$(echo "${GDSAAMOUNT} + ${FILESIZE2}" | bc)
                            # Set gdsa as crypt or not
                            if [ ${ENCRYPTED} == "true" ]; then
                                GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}C"
                            else
                                GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}"
                            fi
                            # Run upload script demonised
                            /app/uploader/upload.sh "${i}" "${GDSA_TO_USE}" &
                            PID=$!
                            FILEBASE=$(basename "${i}")
                            # Add transfer to pid directory
                            echo "${PID}" > "/config/pid/${FILEBASE}.trans"
                            # Increase or reset $GDSAUSE?
                            # shellcheck disable=SC2086
                            if [ ${GDSAAMOUNT} -gt "783831531520" ]; then
                                log "${GDSAARRAY[$GDSAUSE]} has hit 730GB switching to next SA"
                                if [ "${GDSAUSE}" -eq "${GDSACOUNT}" ]; then
                                    GDSAUSE=0
                                    GDSAAMOUNT=0
                                else
                                    GDSAUSE=$(("${GDSAUSE}" + 1))
                                    GDSAAMOUNT=0
                                fi
                                # Record next GDSA in case of crash/reboot
                                echo "${GDSAUSE}" >/config/vars/lastGDSA
                            fi
                            log "${GDSAARRAY[${GDSAUSE}]} is now $(echo "${GDSAAMOUNT}/1024/1024/1024" | bc -l)"
                            # Record GDSA transfered in case of crash/reboot
                            echo "${GDSAAMOUNT}" >/config/vars/gdsaAmount
                        else
                            log "File ${i} seems to have dissapeared"
                        fi
                    else
                        log "Already ${ACTIVETRANSFERS} transfers running, waiting for next loop"
                        break
                    fi
                else
                    log "File not found: ${i}"
                    continue
                fi
            fi
        done
        log "Finished looking for files, sleeping 5 secs"
    else
        log "Nothing to upload, sleeping 5 secs"
    fi
    sleep 5
done
