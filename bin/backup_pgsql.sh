#!/bin/bash


#
#  constants
#
DATABASE_NAME=live-recordings

BACKUP_PATH=~/iCloud/Backup/${DATABASE_NAME}
BACKUP_FILE=${BACKUP_PATH}/${DATABASE_NAME}-$( date "+%Y%m%d-%H%M%S" ).psql.gz

REMOVE_DUPLICATES_SCRIPT=~/bin/remove_duplicate_files.py

EVICT_DAYS=7

mkdir -p "${BACKUP_PATH}"

#
#  backup
#
pg_dump "${DATABASE_NAME}" | gzip > "${BACKUP_FILE}"

#
#  remove duplicates
#
python3 "${REMOVE_DUPLICATES_SCRIPT}" "${BACKUP_PATH}"

#
#  evict old backup files from local disk
#
#find "${BACKUP_PATH}" -mtime +"${EVICT_DAYS}" -exec brctl evict "{}" \;
