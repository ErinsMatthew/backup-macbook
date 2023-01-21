#!/bin/sh


#
#  constants
#
BACKUP_PATH=~/OneDrive/RaspberryPi/$( date "+%Y%m%d-%H%M%S" )

KEY_FILE=~/.ssh/id_pi

PI_HOLE=pi@pi.hole

REMOTE_BASE_PATH=/var/backups


#
#  create backup path
#
mkdir $BACKUP_PATH


#
#  backup
#
for f in crontab.txt home.tgz root.tgz pi-hole-pihole-teleporter.tgz; do
    REMOTE_FILE=$REMOTE_BASE_PATH/$f

    scp -i "$KEY_FILE" "$PI_HOLE:$REMOTE_FILE" "$BACKUP_PATH/$f"
done
