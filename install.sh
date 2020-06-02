#!/bin/sh
#### INSTALL COMMANDS

OVERLAY_ARCH="amd64"
OVERLAY_VERSION="v2.0.0.1"

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
        php7-gd \
        curl \
        nginx \
        libxml2-utils \
        tzdata \
        openntpd \
        grep \
        tar \
        mc && \
  curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" >/dev/null 2>&1 && \
  tar xfz /tmp/s6-overlay.tar.gz -C / >/dev/null 2>&1 && \
  apk add --quiet --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing mergerfs && \
  sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
  wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
    unzip -qq rclone.zip && rm rclone.zip && \
    mv rclone*/rclone /usr/bin && rm -rf rclone* && \
    mkdir -p /unionfs && \
    mkdir -p /config && \
    mkdir -p /move && \
    mkdir -p /mnt && \
	mkdir -p /app/plex && \
    chown 911:911 /unionfs && \
    chown 911:911 /config && \
    chown -hR 911:911 /move && \
    chown -hR 911:911 /mnt && \
    addgroup -g 911 abc && \
    adduser -u 911 -D -G abc abc && \
    chmod +x /app/gdrive/uploader.sh && \
    chmod +x /app/tdrive/uploader.sh && \
    chmod +x /app/uploader/upload.sh && \
    chmod +x /app/mergerfs.sh && \
    chown -hR 911:911 /app/plex && \
    chown 911:911 /app/plex && \
    chown 911:911 /app/uploader/upload.sh && \
    chown 911:911 /app/gdrive/uploader.sh && \
    chown 911:911 /app/tdrive/uploader.sh && \
    chown 911:911 /app/mergerfs.sh && \
    mv /html /var/www && \
	chown -hR 911:911 /var/www/html && \
	chown 911:911 /var/www/html && \
    mv /config/nginx.conf /etc/nginx/nginx.conf && \
    mv /config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf && \
	mv /config/php.ini /etc/php7/conf.d/zzz_custom.ini
	
