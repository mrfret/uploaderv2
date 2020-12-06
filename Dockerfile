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
FROM lsiobase/alpine:3.12
LABEL maintainer=60312740+doob187@users.noreply.github.com

RUN \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add shadow bash bc findutils coreutils && \
  rm -rf /var/cache/apk/*

VOLUME [ "/config" ]

COPY root/ /

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
