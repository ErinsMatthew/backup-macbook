#!/usr/bin/env bash

ICLOUD_DIR='/Users/doof/iCloud/Videos'
GDRIVE_DIR='/Volumes/G-DRIVE ArmorATD'

getFileInfo() {
    gfind "$1" -name ".*" -prune -o -name "Backups" -prune -o -name "Movies" -prune -o -name "Shows" -prune -o -type f -print | sed -E -e "s#$1/##" | grep -v .DS_Store | sort
}

getEmptyDirs() {
    gfind "$1" -name ".*" -prune -o -name "Backups" -prune -o -name "Movies" -prune -o -name "Shows" -prune -o -type d -empty -print | sed -E -e "s#$1/##" | sort
}

echo "### FILES ###"

diff <(getFileInfo "${ICLOUD_DIR}") <(getFileInfo "${GDRIVE_DIR}")

echo "### EMPTY DIRECTORIES ###"

diff <(getEmptyDirs "${ICLOUD_DIR}") <(getEmptyDirs "${GDRIVE_DIR}")
