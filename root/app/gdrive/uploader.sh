#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
## function source
source /app/functions/functions.sh
#Make sure all the folders we need are created
base_folder_gdrive
downloadpath=/move
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
  if grep -q gcrypt /config/rclone-docker.conf; then
     ENCRYPTED=true
  fi
fi
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
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
discord_start_send_gdrive
remove_old_files_start_up
cleanup_start
bc_start_up_test
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
   GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
   GDSAAMOUNT=0
fi
# PLEX=${PLEX:-false}
# GCE=${GCE:-false}
# GCECHECK=$(dnsdomainname | tail -c 10)
# if [[ "${PLEX}" == "false" && "${GCE}" == "false" ]]; then
 # if [ -f /config/plex/docker-preferences.xml ]; then
    # PLEX=true
	# GCE=false
 # elif [ "$gcheck" == ".internal" ]; then
    # PLEX=false
	# GCE=true
 # else
    # PLEX=false
	# GCE=false
 # fi
# fi
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
    mapfile -t files < <(eval find ${downloadpath} -type f ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES})
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
                  sleep 5
                  # Check if file is still getting bigger
                  FILESIZE1=$(stat -c %s "${i}")
                  sleep 5
                  FILESIZE2=$(stat -c %s "${i}")
                  if [ "$FILESIZE1" -ne "$FILESIZE2" ]; then
                     ##log "File is still getting bigger ${i}" 
					 sleep 5 
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
                           log "${GDSA_TO_USE} has hit 730GB uploads will resume when they can ( ︶︿︶)_╭∩╮" 
                           break
                        fi
                        # Add filesize to file
                        echo "${FILESIZE2}" > "/config/vars/gdrive/$(echo "$(date +%s) + 86400" | bc)"
                        # Run plex & upload script demonised
                        /app/uploader/upload.sh "${i}" "${GDSA_TO_USE}" &
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
                      ##log "Already ${UPLOADS} transfers running, waiting for next loop"
                      sleep 10       
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
                sleep 10
            fi
        done
        log "Finished looking for files, sleeping 10 secs"
    else
        log "Nothing to upload, sleeping 10 secs"
    fi
    sleep 10
done
