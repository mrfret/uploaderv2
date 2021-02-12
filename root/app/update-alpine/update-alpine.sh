#!/usr/bin/with-contenv bash
# shellcheck shell=bash
function log() {
echo "[UPDATE] ${1}"
}
# function source start
function install_rclone() {
local AVAILABLE_RCLONE
local LOCAL_RCLONE
AVAILABLE_RCLONE=$(curl -fsL "https://api.github.com/repos/ncw/rclone/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
LOCAL_RCLONE=$(rclone --version | awk '{print $2}' | head -n 1 | sed -e 's/v//g' | cut -c1-6)
if [[ ${AVAILABLE_RCLONE} != ${LOCAL_RCLONE} ]]; then
   log "-> please hold the line ...... <- [UPLOADER]"
   rm -rf /tmp/rclone-** && rm -rf /tmp/rclone.zip
   wget --quiet https://downloads.rclone.org/rclone-current-linux-amd64.zip -O /tmp/rclone.zip
   unzip -q /tmp/rclone.zip && rm -rf /tmp/rclone.zip
   mv /tmp/rclone*/rclone /usr/bin && rm -rf /tmp/rclone*
   log "-> Install now rclone Version ${AVAILABLE_RCLONE} <- [UPLOADER]"
   chown abc:abc /usr/bin/rclone 1>/dev/null 2>&1
   chmod 755 /usr/bin/rclone 1>/dev/null 2>&1
   log "-> update rclone || done <-"
   log "-> Installed rclone Version $(rclone --version | awk '{print $2}' | head -n 1 | sed -e 's/v//g' | cut -c1-6) <- [UPLOADER]"
   update
else
   update
fi
}

function update() {
log "-> update packages || start <-"
    apk --no-cache update --quiet && apk --no-cache upgrade --quiet && apk --no-cache fix --quiet
    apk del --quiet --clean-protected --no-progress
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
}
function enbanner() {
if [[ $(command -v rclone | wc -l) == "1" ]]; then
    chown -cf abc:abc /root/
fi
}
install_rclone
update
enbanner
#<EOF>#
