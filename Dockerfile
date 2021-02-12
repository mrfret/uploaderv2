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
FROM lsiobase/alpine:3.13
LABEL maintainer=doob187

RUN \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add curl unzip shadow bash bc findutils coreutils && \
  rm -rf /var/cache/apk/*

RUN \
   rm -rf /tmp/rclone-*-linux-amd64  && \
   rm -rf /tmp/rclone.zip && \
   wget --quiet https://downloads.rclone.org/rclone-current-linux-amd64.zip -O /tmp/rclone.zip && \
   unzip -q /tmp/rclone.zip && \
   rm -rf /tmp/rclone.zip && \
   mv /tmp/rclone-*-linux-amd64/rclone /usr/bin && \
   rm -rf /tmp/rclone-*-linux-amd64

VOLUME [ "/config" ]

COPY root/ /

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
