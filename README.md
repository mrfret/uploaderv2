# docker_uploader

## Inital Setup

```sh
mkdir -p /opt/uploader/keys
```

Copy your rclone file to ``/opt/uploader``
Use the following to fix the service file paths

```sh
OLDPATH=/youtoldpath/keys/
sed -i "s#${OLDPATH}#/config/keys/#g" /opt/uploader/rclone.conf
```

ENVS for the setup 
```
UPLOADS = can be used from 1 - 20
BWLIMITSET = 10 - 100
GCE = true or false  for maxout  the upload speed 
PLEX = true or false
TZ = for local timezone 
DISCORD_WEBHOOK_URL = for using Discord to track the Uploads
DISCORD_ICON_OVERRIDE = Discord Avatar 
DISCORD_NAME_OVERRIDE = Name for the Discord Webhook User
LOGHOLDUI = When Diacord is not used, the Complete Uploads will stay there
```
NOTE : 

``` 
SAMPLE FOR BWLIMITSET  AND UPLOADS 

BWLIMITSET  is set to 100
UPLOADS     is set to 10 

BWLIMITSET  / UPLOADS  = REAL UPLOADSPEED PER FILE 
```

VOLUMES:
```sh
Folder to upload           =  - /mnt/move:/move
Folder for config          =  - /opt/uploader:/config
Folder for the plexscript  =  - /opt/uploader/plexstreams:/app/plex
Dolder for merged contest  =  - /mnt/<pathofmergerfsrootfolder>:/unionfs
```

PORTS 
```sh

PORT A ( HOST )      = 7777
PORT B ( CONTAINER ) = 8080

```
Rclone.conf file must be placed under  ```/opt/uploader```
rclone.conf :

## Uploader

Uploader will look for remotes in the ``rclone.conf``
starting with ``PG``, ``GD``, ``GS`` to upload with

Default files to be ignored by Uploader are

``! -name '*partial~'``
``! -name '*_HIDDEN~'``
``! -name '*.fuse_hidden*'``
``! -name '*.lck'``
``! -name '*.version'``
``! -path '.unionfs-fuse/*'``
``! -path '.unionfs/*'``
``! -path '*.inProgress/*'``

You can add additional ignores using the ENV ``ADDITIONAL_IGNORES`` e.g.

```sh
-e "ADDITIONAL_IGNORES=! -path '*/SocialMediaDumper/*' ! -path '*/test/*'"
```

-----

Whats new in this UPLOADER : 

- WebUI is colored 
- s6-overlay is using the latest version 
- alpine docker is using latest version
- some ENV are adddd for more user friendly systems
- mobile version is included 
- it will automatically  reduce tbe bandwidth when plex is running
- it will not max out the upload speed

-----

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
    labels:
      - "traefik.enable=true"
      - "traefik.frontend.redirect.entryPoint=https"
      - "traefik.frontend.rule=Host:uploader.example.com"
      - "traefik.port=8080"
    networks:
      - traefik_proxy
    restart: always

```
