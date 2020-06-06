# docker_uploader

## Inital Setup

```
mkdir -p /opt/uploader/{keys,plex}
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

## ENVS for the setup 

```
UPLOADS = can be used from 1 - 20
BWLIMITSET = 10 - 100
GCE = true or false  for maxout  the upload speed 
PLEX = true or false
TZ = for local timezone 
DISCORD_WEBHOOK_URL = for using Discord to track the Uploads
DISCORD_ICON_OVERRIDE = Discord Avatar 
DISCORD_NAME_OVERRIDE = Name for the Discord Webhook User
LOGHOLDUI = When Diacord-Webhook is not used, the Complete Uploads will stay there for the minutes you setup
PLEX_SERVER_IP="plex" = you can use IP and localhost and traefik_proxy part 
PLEX_SERVER_PORT="32400" = the plex port (! local accesible !)

```

-----

## NOTE: 

```

SAMPLE FOR BWLIMITSET AND UPLOADS 

BWLIMITSET  is set to 100
UPLOADS     is set to 10 

BWLIMITSET  / UPLOADS  = REAL UPLOADSPEED PER FILE 

```
-----

## VOLUMES:

```

Folder for uploads              =  - /mnt/move:/move
Folder for config               =  - /opt/uploader:/config
Folder for the plex Preference  =  - /opt/uploader/plex:/app/plex
Dolder for merged contest       =  - /mnt/<pathofmergerfsrootfolder>:/unionfs

```

-----

## PORTS 

```

PORT A ( HOST )      = 7777
PORT B ( CONTAINER ) = 8080

```

-----


## Uploader

Uploader will look for remotes in the ``rclone.conf``
starting with ``PG``, ``GD``, ``GS`` to upload with

Default files to be ignored by Uploader are

```

! -name '*partial~'
! -name '*_HIDDEN~'
! -name '*.fuse_hidden*'
! -name '*.lck'
! -name '*.version'
! -path '.unionfs-fuse/*'
! -path '.unionfs/*'
! -path '*.inProgress/*'

```

You can add additional ignores using the ENV ``ADDITIONAL_IGNORES`` e.g.

```

-e "ADDITIONAL_IGNORES=! -path '*/SocialMediaDumper/*' ! -path '*/test/*'"

```

-----

## CHANGELOG

Whats new in this UPLOADER : 

- WebUI is colored 
- s6-overlay is using the latest version 
- alpine-docker-image is using latest version
- some ENV are added for more user friendly systems [ see above ENVS ]
- mobile version is included 
- it will automatically reduce the bandwidth when plex is running [ see above ENVS ]
- it will not max out the upload speed [ see above ENVS ]
- Preference.xml will now edit to docker-preferences.xml
- 2 failsafe mods for reading/edit the docker-preferences.xml and /app/plex folder 



- NEW FEATURES in the next time !! 

-----

## Bug or Feature Requests 

I don't open the original repo for the world,

You want a feature or you found a bug,

https://github.com/doob187/uploader-bug-tracker/issues

sinple create here a issue for bug or feature requests 

-----

NOTE: Running Plex Server and Docker Uploader at the same time / same host

- it will automatically  reduce the bandwidth when plex is running

```
it will use follow variables for this

When streams are running :

BWLIMITSET = see above 
PLEX_PLAYS = inside running command

BWLIMITSET / PLEX_PLAYS = UPLOADSPEED per file

When no_streams are running or under 2 streams :

BWLIMITSET = see above
UPLOADS = see above 

BWLIMITSET / UPLOADS = UPLOADSPEED per file

```

--------

## TRAEFIK

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

Original coder is ```physk/rclone-mergerfs``` on gitlab

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
      - "UPLOADS=4"
      - "BWLIMITSET=80"
      - "CHUNK=32"
      - "PLEX=false"
      - "GCE=false"
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
      - "/opt/uploader/plexstreams:/app/plex"
      - "/mnt/unionfs:/unionfs:shared"
    ports:
      - "7777:8080"
    restart: always

```
-----

(c) 2020 MrDoob 
