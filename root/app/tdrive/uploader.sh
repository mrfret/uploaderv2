#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
# Logging Function
function log() {
 echo "[Uploader] ${1}"
}
#Make sure all the folders we need are created
path=/config/keys/
mkdir -p /config/pid/
mkdir -p /config/json/
mkdir -p /config/logs/
mkdir -p /config/vars/
mkdir -p /config/discord/
downloadpath=/move
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
UPLOADS=${UPLOADS}
if [ "${UPLOADS}" == 'null' ]; then
   UPLOADS="8"
elif [ "${UPLOADS}" -ge '20' ]; then
   UPLOADS="8"
else
   UPLOADS=${UPLOADS}
fi
HOLDFILESONDRIVE=${HOLDFILESONDRIVE}
if [ "${HOLDFILESONDRIVE}" == 'null' ]; then
   HOLDFILESONDRIVE="2"
fi
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}
DISCORD="/config/discord/startup.discord"
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
  echo "Upload Docker is Starting \nStarted for the First Time \nCleaning up if from reboot \nUploads is set to ${UPLOADS}\nHOLDFILESONDRIVE is set to ${HOLDFILESONDRIVE} min " >"${DISCORD}"
  message=$(cat "${DISCORD}")
  msg_content=\"$message\"
  USERNAME=\"${DISCORD_NAME_OVERRIDE}\"
  IMAGE=\"${DISCORD_ICON_OVERRIDE}\"
  DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL}"
  curl -H "Content-Type: application/json" -X POST -d "{\"username\": $USERNAME, \"avatar_url\": $IMAGE, \"content\": $msg_content}" $DISCORD_WEBHOOK_URL
else
  log "Upload Docker is Starting"
  log "Started for the First Time - Cleaning up if from reboot"
  log "Uploads is set to ${UPLOADS}"
  log "HOLDFILESONDRIVE is set to ${HOLDFILESONDRIVE} min"
fi
# Remove left over webui and transfer files
rm -f /config/pid/*
rm -f /config/json/*
rm -f /config/logs/*
rm -f /config/discord/*
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
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
   GDSAUSE=$(cat /config/vars/lastGDSA)
   GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
   GDSAUSE=0
   GDSAAMOUNT=0
fi
# Run Loop
while true; do
    #Find files to transfer
    IFS=$'\n'
    mapfile -t files < <(eval find ${downloadpath} -type f ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES} -mmin +${HOLDFILESONDRIVE} | sort -k1 )
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
                        sleep 10
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
                      log "Already ${UPLOADS} transfers running, waiting for next loop"
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
              sleep 5
           fi
       done
       log "Finished looking for files, sleeping 5 secs"
   else
       log "Nothing to upload, sleeping 5 secs"
   fi
   sleep 5
done
