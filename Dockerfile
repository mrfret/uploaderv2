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
FROM golang:alpine AS build-env
RUN apk add --no-cache git
RUN go get -u -v github.com/ncw/rclone
RUN /go/bin/rclone version
FROM alpine:latest
LABEL maintainer=60312740+doob187@users.noreply.github.com
ENV ADDITIONAL_IGNORES=null \
    SERVERSIDEMINAGE=null \
    SERVERSIDE=false \
    CHUNK="32" \
    TZ="Europe/Berlin" \
    DISCORD_WEBHOOK_URL=null \
    DISCORD_ICON_OVERRIDE="https://i.imgur.com/MZYwA1I.png" \
    DISCORD_NAME_OVERRIDE="RCLONE" \
    DISCORD_EMBED_TITEL="Upload Completed" \
    BWLIMITSET=null \
    CLEANUPDOWN=null \
    MINAGE=null \
    SERVERSIDEDAY=null \
    LOGHOLDUI="5m" \
    CAPACITY_LIMIT=null

COPY root/ /

RUN \
 echo "**** install build packages ****" && \
 apk add --quiet --no-cache --no-progress \
        ca-certificates logrotate shadow bash  bc findutils coreutils openssl php7 php7-fpm php7-mysqli php7-json php7-openssl \
        php7-curl php7-zlib php7-xml php7-phar php7-dom php7-xmlreader php7-ctype php7-mbstring php7-gd \
        curl nginx libxml2-utils tzdata openntpd grep tar fuse

RUN \
  echo "**** Install s6-overlay ****" && \ 
  curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' > /etc/S6_RELEASE && \
  wget https://github.com/just-containers/s6-overlay/releases/download/`cat /etc/S6_RELEASE`/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C / >/dev/null 2>&1 && \
  rm /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  echo "**** Installed s6-overlay `cat /etc/S6_RELEASE` ****"

VOLUME [ "/config" ]
VOLUME [ "/move" ]

RUN chown 911:911 /config && \
    chown -hR 911:911 /move && \
    chown -hR 911:911 /mnt && \
    mkdir -p /var/www/html && \
    addgroup -g 911 abc && \
    adduser -u 911 -D -G abc abc

COPY --from=build-env /go/bin/rclone /usr/bin/rclone
COPY --chown=abc html/ /var/www/html
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

EXPOSE 8080

HEALTHCHECK --timeout=5s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
