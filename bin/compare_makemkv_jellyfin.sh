#!/usr/bin/env bash

MAKEMKV_DIR='/Users/doof/MakeMKV Working Folder'
JELLYFIN_DIR='/Users/doof/Jellyfin/movies'

getFileInfo() {
    gfind "$1" -type f -print | sed -E -e "s#$1/##" | grep -v .DS_Store | sort
}

getEmptyDirs() {
    gfind "$1" -type d -empty -print | sed -E -e "s#$1/##" | sort
}

echo "### FILES ###"

diff <(getFileInfo "${MAKEMKV_DIR}") <(getFileInfo "${JELLYFIN_DIR}")

echo "### EMPTY DIRECTORIES ###"

diff <(getEmptyDirs "${MAKEMKV_DIR}") <(getEmptyDirs "${JELLYFIN_DIR}")
