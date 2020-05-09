#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
# Logging Function
function log() {
    echo "[Uploader] ${1}"
}
#Make sure all the folders we need are created
mkdir -p /config/pid/
mkdir -p /config/json/
mkdir -p /config/logs/
mkdir -p /config/vars/
mkdir -p /config/vars/gdrive/
downloadpath=/move
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
    if grep -q gcrypt /config/rclone-docker.conf; then
          ENCRYPTED=true
    fi
fi
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
    ADDITIONAL_IGNORES=""
fi
UPLOADS=${UPLOADS}
if [ "${UPLOADS}" == 'null' ]; then
   UPLOADS="8"
elif [ "${UPLOADS}" -ge '20' ]; then
   UPLOADS="8"
else
   UPLOADS=${UPLOADS}
fi
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
  if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
    log "Upload Docker is Starting and Uploads is set to ${UPLOADS}" >/tmp/startup.done
    message=$(cat /tmp/startup.done)
    msg_content=\"$message\"
    USERNAME=\"${DISCORD_NAME_OVERRIDE}\"
    IMAGE=\"${DISCORD_ICON_OVERRIDE}\"
    DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/696323114383966268/EFLjnupPrRc-vs87fJAB2alXNWRhoj6XrZsE3iw0K7AV2LN_6IxNsrohN8cxjWoy6qrO"
    curl -H "Content-Type: application/json" -X POST -d "{\"username\": $USERNAME, \"avatar_url\": $IMAGE, \"content\": $msg_content}" $DISCORD_WEBHOOK_URL
	rm -f /tmp/startup.done
  else
    log "Upload Docker is Starting"
    log "Started for the First Time - Cleaning up if from reboot"
    log "Uploads is set to ${UPLOADS}"
  fi
# Remove left over webui and transfer files
rm -f /config/pid/*
rm -f /config/json/*
rm -f /config/logs/*
# delete any lock files for files that failed to upload
find ${downloadpath} -type f -name '*.lck' -delete
log "Cleaned up - Sleeping 10 secs"
sleep 10
# Check if BC is installed
if [ "$(echo "10 + 10" | bc)" == "20" ]; then
    log "BC Found! All good :)"
else
    log "BC Not installed, Exit"
    exit 2
fi
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
    GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
    GDSAAMOUNT=0
fi
# Run Loop
while true; do
    mapfile -t timestamps < <(eval find /config/vars/gdrive -type f)
    for file in "${timestamps[@]}";
    do
        if [ "$(basename "${file}")" -ge "$(date +%s)" ]; then
            tmpamount=$(echo "${GDSAAMOUNT} - $(cat "${file}")" | bc)
            if [[ "${tmpamount}" =~ ^[0-9]+$ ]]; then
                log "taking $(cat "${file}") from ${GDSAAMOUNT}"
                GDSAAMOUNT=${tmpamount}
            else
                GDSAAMOUNT=0
            fi
            rm -fr "${file}"
        fi
    done
    #Find files to transfer
    IFS=$'\n'
    mapfile -t files < <(eval find ${downloadpath} -type f ! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*' ${ADDITIONAL_IGNORES})
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
                    sleep 3
                    FILESIZE2=$(stat -c %s "${i}")
                    if [ "$FILESIZE1" -ne "$FILESIZE2" ]; then
                        log "File is still getting bigger ${i}"
                        continue
                    fi
                    # Check if we have any upload slots available
			        # shellcheck disable=SC2010
                    TRANSFERS=$(ls -la /config/pid/ | grep -c trans)
                    # shellcheck disable=SC2086
                    if [ ! ${TRANSFERS} -ge ${UPLOADS} ]; then
                        if [ -e "${i}" ]; then
                            log "Starting upload of ${i}"
                            # Append filesize to GDSAAMOUNT
                            GDSAAMOUNT=$(echo "${GDSAAMOUNT} + ${FILESIZE2}" | bc)
                            # Set gdrive as crypt or not
                            if [ ${ENCRYPTED} == "true" ]; then
                                GDSA_TO_USE="gcrypt"
                            else
                                GDSA_TO_USE="gdrive"
                            fi
                            # Increase or reset $GDSAUSE?
                            # shellcheck disable=SC2086
                            if [ ${GDSAAMOUNT} -gt "783831531520" ]; then
                                log "gdrive has hit 730GB uploads will resume when they can ( ︶︿︶)_╭∩╮"
                                break
                            fi
                            # Add filesize to file
                            echo "${FILESIZE2}" > "/config/vars/gdrive/$(echo "$(date +%s) + 86400" | bc)"
                            # Run upload script demonised
                            /app/gdrive/upload.sh "${i}" "${GDSA_TO_USE}" &
                            PID=$!
                            FILEBASE=$(basename "${i}")
                            # Add transfer to pid directory
                            echo "${PID}" > "/config/pid/${FILEBASE}.trans"
                            log "gdrive is now $(echo "${GDSAAMOUNT}/1024/1024/1024" | bc -l)"

                            # Record GDSA transfered in case of crash/reboot
                            echo "gdrive" >/config/vars/lastGDSA
                            echo "${GDSAAMOUNT}" >/config/vars/gdsaAmount
                        else
                            log "File ${i} seems to have dissapeared"
                        fi
                    else
                        log "Already ${UPLOADS} transfers running, waiting for next loop"
                        break
                    fi
                else
                    log "File not found: ${i}"
                    continue
                fi
            fi
            if [[ -d "/mnt/gdrive/${FILEDIR}" || -d "/mnt/gcrypt/${FILEDIR}" ]]; then
                continue
            else
                log "Sleeping 5s before looking at next file"
                sleep 5
            fi
        done
        log "Finished looking for files, sleeping 5 secs"
    else
        log "Nothing to upload, sleeping 5 secs"
    fi
    sleep 5
done
