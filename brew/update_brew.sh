#!/usr/bin/env bash

set -o nounset

#
#  constants
#
BACKUP_PATH=~/iCloud/Brewfiles
BACKUP_FILE=${BACKUP_PATH}/Brewfile.$( date "+%Y%m%d-%H%M%S" )

REMOVE_DUPLICATES_SCRIPT=~/bin/remove_duplicate_files.py

EVICT_DAYS=7

#
#  backup brews
#
brew bundle dump -f && mv Brewfile "${BACKUP_FILE}"

#
#  remove duplicates
#
python3 "${REMOVE_DUPLICATES_SCRIPT}" "${BACKUP_PATH}"

#
#  evict old Brewfiles from local disk
#
find "${BACKUP_PATH}" -mtime +"${EVICT_DAYS}" -exec brctl evict "{}" \;

#
#  update and upgrade
#
if brew update && brew update; then
    #
    #  upgrade formulae
    #
    brew upgrade

    #
    #  upgrade casks
    #
    brew upgrade --cask
fi

#
#  cleanup
#
brew cleanup
brew cleanup cask
