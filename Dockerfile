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
#FROM ghcr.io/linuxserver/baseimage-alpine:latest
FROM lsiobase/alpine:3.13
LABEL maintainer=60312740+doob187@users.noreply.github.com

RUN \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add curl unzip shadow bash bc findutils coreutils && \
  rm -rf /var/cache/apk/*

RUN \
  curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
  unzip -q rclone-current-linux-amd64.zip && \
  rm -f rclone-current-linux-amd64.zip && \
  cd rclone-*-linux-amd64 && \
  cp rclone /usr/bin/

VOLUME [ "/config" ]

COPY root/ /

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
