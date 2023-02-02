#!/bin/bash


#
#  constants
#
BACKUP_PATH=~/OneDrive/MacAppsListFiles
BACKUP_FILE=$BACKUP_PATH/MacApps.$( date "+%Y%m%d-%H%M%S" )

REMOVE_DUPLICATES_SCRIPT=~/bin/remove_duplicate_brewfiles.py


#
#  backup applications list
#
ls /Applications |sed 's/\.app\///' > $BACKUP_FILE


#
#  remove duplicates
#
python3 $REMOVE_DUPLICATES_SCRIPT "$BACKUP_PATH"
