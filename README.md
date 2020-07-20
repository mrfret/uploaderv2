# DOCKER UPLOADER

----

## INITIAL SETUP

```
mkdir -p /opt/uploader/keys
```

Copy your rclone file to ``/opt/uploader``
Use the following to fix the service file paths
```
(( RUNNING PLEX SERVER SAME HOST ))
```
Copy your PLEX - Preference.xml file to ```/opt/uploader/plex```
```sh
(( RUNNING PLEX SERVER SAME HOST ))
```


```sh
OLDPATH=/youroldpath/keys/
sed -i "s#${OLDPATH}#/config/keys/#g" /opt/uploader/rclone.conf
```
-----

## ENVS FOR THE SETUP

```
BWLIMITSET = 10 - 100
TZ = for local timezone 
DISCORD_WEBHOOK_URL = for using Discord to track the Uploads
DISCORD_ICON_OVERRIDE = Discord Avatar 
DISCORD_NAME_OVERRIDE = Name for the Discord Webhook User
LOGHOLDUI = When Diacord-Webhook is not used, the Complete Uploads will stay there for the minutes you setup

SERVERSIDEMINAGE = only valid  parts check rclone.org for more infos about --min-age  ||>> 1d - 30d || 1h - 24h || 1m - 12m 
[[ basic is 48h ]]
SERVERSIDE = true or false
This means if you want to move one folder to another then rclone won't download all the files and re-upload them; 
it will instruct the server to move them in place.


```
-----


## VOLUMES


```

Folder for uploads              =  - /mnt/move:/move
Folder for config               =  - /opt/uploader:/config
Dolder for merged contest       =  - /mnt/<pathofmergerfsrootfolder>:/unionfs

```

-----


## PORTS


```

PORT A ( HOST )      = 7777
PORT B ( CONTAINER ) = 8080

```

-----


## UPLOADER

Uploader will look for remotes in the ``*rclone.conf*``
starting with ``PG``, ``GD``, ``GS`` to upload with

> **DEFAULT FILES TO BE IGNORED BY UPLOADER:**

```

! -name '*partial~'
! -name '*_HIDDEN~'
! -name '*.fuse_hidden*'
! -name '*.lck'
! -name '*.version'

```

> **DEFAULT PATHS TO BE IGNORED BY UPLOADER:**

```

! -path '.unionfs-fuse/*'
! -path '.unionfs/*'
! -path '*.inProgress/*'
! -path '**torrent/**' 
! -path '**nzb/**' 
! -path '**backup/**' 
! -path '**nzbget/**' 
! -path '**jdownloader2/**' 
! -path '**sabnzbd/**' 
! -path '**rutorrent/**' 
! -path '**deluge/**' 
! -path '**qbittorrent/**')

```

> **SIMILARLY ADDITIONAL IGNORES CAN BE SET USING ENV ``ADDITIONAL_IGNORES`` EXAMPLE:**

```

-e "ADDITIONAL_IGNORES=! -path '*/SocialMediaDumper/*' ! -path '*/test/*'"

```

-----

## CHANGELOG

> - WebUI is colored 
> - s6-overlay:latest version 
> - alpine-docker-image:latest version
> - Additional ENV variables added
> - WEB-UI is optimized for Cellphones 
> - Upload speed throtlling
> - Preference.xml (used for bandwidth throtlling whilst a plex stream is running) is now automatically copied and named docker-preferences.xml
> - 2 failsafe mods added reading/edit the docker-preferences.xml
> - server-side included now ( starts each Sunday in the background ) / from tdrive to gdrive /
> - TCrypt and GCrypt password/salt passwords checks for server-side included


- NEW FEATURES COMING !! 

-----

## BUGS/FEATURE-REQUESTS  

> **The repo is maintained privatley for any bug or feature requests:**
https://github.com/doob187/uploader-bug-tracker/issues


-----

## TRAEFIK v1.7

```
    labels:
      - "traefik.enable=true"
      - "traefik.frontend.redirect.entryPoint=https"
      - "traefik.frontend.rule=Host:uploader.example.com"
      - "traefik.frontend.headers.SSLHost=example.com"
      - "traefik.frontend.headers.SSLRedirect=true"
      - "traefik.frontend.headers.STSIncludeSubdomains=true"
      - "traefik.frontend.headers.STSPreload=true"
      - "traefik.frontend.headers.STSSeconds=315360000"
      - "traefik.frontend.headers.browserXSSFilter=true"
      - "traefik.frontend.headers.contentTypeNosniff=true"
      - "traefik.frontend.headers.customResponseHeaders=X-Robots-Tag:noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex"
      - "traefik.frontend.headers.forceSTSHeader=true"
      - "traefik.port=8080"
    networks:
      - traefik_proxy_sample_network

```

-----

## ORIGINAL CODER \ CREDITS

> Original coder is ```physk/rclone-mergerfs``` on gitlab

-----

docker-composer.yml 

```

version: "3"
services:
  uploader:
    container_name: uploader
    image: mrdoob/rccup:latest
    privileged: true
    cap_add:
      - SYS_ADMIN
    devices:
      - "/dev/fuse"
    security_opt:
      - "apparmor:unconfined"
    environment:
      - "ADDITIONAL_IGNORES=null'
      - 'SERVERSIDEMINAGE=null'
      - "BWLIMITSET=80"
      - "CHUNK=32"
      - "TZ=Europe/Berlin"
      - "DISCORD_WEBHOOK_URL=null"
      - "DISCORD_ICON_OVERRIDE=https://i.imgur.com/MZYwA1I.png"
      - "DISCORD_NAME_OVERRIDE=UPLOADER"
      - "LOGHOLDUI=5m"
      - "PUID=${PUID}"
      - "PGID=${PUID}"
    volumes:
      - "/mnt/move:/move"
      - "/opt/uploader:/config"
      - "/mnt/unionfs:/unionfs:shared"
    ports:
      - "7777:8080"
    restart: always

```
-----

(c) 2020 MrDoob 
