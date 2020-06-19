######################################################
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

ARG OVERLAY_ARCH="amd64"
ARG OVERLAY_VERSION="v2.0.0.1"

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
    DISCORD_EMBED_TITEL="Upload Completed" \
    LOGHOLDUI="5m" \
    HOLDFILESONDRIVE=null \
    PLEX_SERVER_IP="plex" \
    PLEX_SERVER_PORT="32400"

RUN \
 echo "**** install build packages ****" && \
 echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
 apk update -qq && apk upgrade -qq && apk fix -qq && \
 apk add --quiet --no-cache \
        ca-certificates \
        logrotate \
        shadow \
        bash \
        bc \
        findutils \
        coreutils \
        openssl \
        php7 \
        php7-fpm \
        php7-mysqli \
        php7-json \
        php7-openssl \
        php7-curl \
        php7-zlib \
        php7-xml \
        php7-phar \
        php7-dom \
        php7-xmlreader \
        php7-ctype \
        php7-mbstring \
        php7-gd \
        curl \
        nginx \
        libxml2-utils \
        tzdata \
        openntpd \
        grep \
        tar && \
 echo "**** ${OVERLAY_VERSION} used ****" && \
  curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" >/dev/null 2>&1 && \
  tar xfz /tmp/s6-overlay.tar.gz -C / >/dev/null 2>&1 && \
  apk update -qq && apk upgrade -qq && apk fix -qq && \
  rm -rf /var/cache/apk/* && \
 echo "**** configure mergerfs ****" && \
  apk add --quiet --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing mergerfs && \
  sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf 

VOLUME [ "/unionfs" ]
VOLUME [ "/config" ]
VOLUME [ "/move" ]

RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
    unzip -qq rclone.zip && rm rclone.zip && \
    mv rclone*/rclone /usr/bin && rm -rf rclone* && \
    chown 911:911 /unionfs && \
    chown 911:911 /config && \
    chown -hR 911:911 /move && \
    chown -hR 911:911 /mnt && \
    mkdir -p /var/www/html && \
    addgroup -g 911 abc && \
    adduser -u 911 -D -G abc abc

COPY root/ /
COPY --chown=abc html/ /var/www/html && \
     config/nginx.conf /etc/nginx/nginx.conf && \
     config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf && \
     config/php.ini /etc/php7/conf.d/zzz_custom.ini

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]