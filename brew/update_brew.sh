#!/bin/sh


#
#  constants
#
BACKUP_PATH=~/OneDrive/Brewfiles
BACKUP_FILE=$BACKUP_PATH/Brewfile.$( date "+%Y%m%d-%H%M%S" )

REMOVE_DUPLICATES_SCRIPT=~/bin/remove_duplicate_brewfiles.py


#
#  backup brews
#
brew bundle dump -f && mv Brewfile $BACKUP_FILE


#
#  remove duplicates
#
python3 $REMOVE_DUPLICATES_SCRIPT "$BACKUP_PATH"


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
