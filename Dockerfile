######################################################
# Original coder PhysK                               #
# All rights reserved.                               #
# mod from MrDoob                                    #
# plex stream checker is owned by my self            #
# no one is allowed to modifie or use for his projekt#
######################################################
########## fuck of the hater bitches ! ###############
######################################################
FROM alpine:latest
LABEL maintainer="MrDoob made my day"

ENV ADDITIONAL_IGNORES=null \
    UPLOADS="4" \
    BWLIMITSET="80" \
    CHUNK="32" \
    PLEX="true" \
    GCE="false" \
    TZ="Europe/Berlin" \
    DISCORD_WEBHOOK_URL=null \
    DISCORD_ICON_OVERRIDE="https://i.imgur.com/MZYwA1I.png" \
    DISCORD_NAME_OVERRIDE="RCLONE" \
    LOGHOLDUI="5m" \
    PLEX_SERVER_IP="plex" \
    PLEX_SERVER_PORT="32400"

COPY ./install.sh /
COPY root/ /
RUN chmod +x /install.sh
RUN /install.sh

# Add volumes
VOLUME [ "/unionfs" ]
VOLUME [ "/config" ]
VOLUME [ "/move" ]

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
