#!/usr/bin/env bash

set -o nounset

#
#  constants
#
PASSPHRASE_LENGTH=2048
PASSPHRASE_FILE=~/Code/passphrase-$( date "+%Y%m%d-%H%M%S" ).txt


openssl rand -base64 ${PASSPHRASE_LENGTH} > "${PASSPHRASE_FILE}"
