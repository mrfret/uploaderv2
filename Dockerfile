######################################################
######################################################
# Original coder PhysK                               #
# All rights reserved.                               #
# mod from MrDoob                                    #
# es wird keinem erlaubt                             #
# es in seinem Projekt einzubauen                    #
# ohne meine Erlaubnis / Anfange oder sonstiges      # 
######################################################
########   ich scheiß auf alle ihr hajos   ###########
######################################################
FROM alpine:latest

LABEL maintainer=60312740+doob187@users.noreply.github.com
COPY root/ /


RUN \
  echo "**** update system ****" && \
  apk --quiet --no-cache --no-progress update && \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add shadow curl wget bash bc findutils coreutils grep tar && \
  echo "**** upgrade system ****" && \
  apk --quiet --no-cache --no-progress upgrade && \
  echo "**** Install s6-overlay ****" && \ 
  curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' > /etc/S6_RELEASE && \
  wget https://github.com/just-containers/s6-overlay/releases/download/`cat /etc/S6_RELEASE`/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C / >/dev/null 2>&1 && \
  rm /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  echo "**** Installed s6-overlay `cat /etc/S6_RELEASE` ****" && \
  rm -rf /var/cache/apk/*

VOLUME [ "/config" ]

RUN chown 911:911 /config && \
    addgroup -g 911 abc && \
    adduser -u 911 -D -G abc abc

EXPOSE 8080

#HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
