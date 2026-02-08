#!/bin/bash


#
#  constants
#
BACKUP_PATH=~/iCloud/RaspberryPi/$( date "+%Y%m%d-%H%M%S" )

KEY_FILE=~/.ssh/id_pi

#PI_HOLE=pi@pi.hole
PI_HOLE=pi@192.168.1.129

REMOTE_BASE_PATH=/var/backups


#
#  create backup path
#
mkdir $BACKUP_PATH

declare -a files=(
    'crontab.txt'
    'home.tgz'
    'root.tgz'
    'etc-fstab'
    'netgear-cm-logs-exporter.tgz'
    'pi-hole-pihole-teleporter.tgz'
    'grafana-config.tgz'
    'grafana.db.backup'
    'unbound-config.tgz'
    'jellyfin-config.tgz'
    'jellyfin-metadata.tgz'
    'debian.packages.list'
    'debian.sources.list'
    'sudoers.d.tgz'
    'config.txt'
)


#
#  backup
#
for f in "${files[@]}"; do
    REMOTE_FILE=$REMOTE_BASE_PATH/$f

    scp -i "$KEY_FILE" "$PI_HOLE:$REMOTE_FILE" "$BACKUP_PATH/$f"
done
