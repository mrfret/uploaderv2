#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
## function source
source /app/functions/functions.sh
#Make sure all the folders we need are created
base_folder_tdrive
downloadpath=/move
path=/config/keys/
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
 if grep -q GDSA01C /config/rclone-docker.conf && grep -q GDSA02C /config/rclone-docker.conf; then
    ENCRYPTED=true
 fi
fi
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '*.inProgress/*'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi

getenvs
discord_start_send_tdrive
remove_old_files_start_up
cleanup_start
bc_start_up_test
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
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
   GDSAUSE=$(cat /config/vars/lastGDSA)
   GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
   GDSAUSE=0
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
                    # shellcheck disable=SC2010
                    TRANSFERS=$(ls -la /config/pid/ | grep -c trans)
                    # shellcheck disable=SC2086
                    if [ ! ${TRANSFERS} -ge ${UPLOADS} ]; then
                       if [ -e "${i}" ]; then
                          log "Starting upload of ${i}"
                           GDSAAMOUNT=$(echo "${GDSAAMOUNT} + ${FILESIZE2}" | bc)
                           # Set gdsa as crypt or not
                           if [ ${ENCRYPTED} == "true" ]; then
                              GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}C"
                           else
                              GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}"
                           fi
                           /app/uploader/upload.sh "${i}" "${GDSA_TO_USE}" &
                           PID=$!
                           FILEBASE=$(basename "${i}")
                           echo "${PID}" > "/config/pid/${FILEBASE}.trans"
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
                      ##log "Already ${UPLOADS} transfers running, waiting for next loop" 
					  break
                   fi
               else
                  log "File not found: ${i}"
				  continue
               fi
           fi
           if [[ -d "/mnt/tdrive1/${FILEDIR}" || -d "/mnt/tdrive2/${FILEDIR}" ]]; then
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
