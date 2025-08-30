#!/usr/bin/env bash

set -o nounset

usage() {
    cat << EOT 1>&2
Usage: sync_jellyfin.sh [-adms]

 OPTIONS
 =======
 -a        sync all libraries
 -d        output debug information
 -m        sync movies library
 -s        sync shows library

EOT

  exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'
        [LOCAL_JELLYFIN_DIR]='/Users/doof/Jellyfin'
        [EXCLUDE_FILE_NAME]='rsync_exclusions.txt'
        [EXCLUDE_FILE]=''
        [REMOTE_USER]='pi'
        [REMOTE_HOST]='pihole'
        [REMOTE_JELLYFIN_DIR]='/jellyfin'
    )

    declare -ag LIBRARIES=()
}

debug() {
    if [[ ${GLOBALS[DEBUG]} == 'true' ]]; then
        echo "$@"
    fi
}

process_options() {
    local flag
    local OPTARG    # set by getopts
    local OPTIND    # set by getopts

    while getopts ":adms" flag; do
        case "${flag}" in
            a)
                LIBRARIES+=(
                  'movies'
                  'music'
                  'shows'
                )

                debug "Synching all libraries."
                ;;

            d)
                GLOBALS[DEBUG]='true'

                debug "Debug mode turned on."
                ;;

            m)
                LIBRARIES+=(
                  'movies'
                )

                debug "Library set to movies."
                ;;

            s)
                LIBRARIES+=(
                  'shows'
                )

                debug "Library set to shows."
                ;;

            *)
                usage
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))

    GLOBALS[EXCLUDE_FILE]=$(realpath "${GLOBALS[LOCAL_JELLYFIN_DIR]}/${GLOBALS[EXCLUDE_FILE_NAME]}")
}

sync_folders() {
    local local_path
    local remote_user_host
    local remote_path

    local library

    library=$1

    local_path="${GLOBALS[LOCAL_JELLYFIN_DIR]}/${library}"

    if [[ ! -d ${local_path} ]]; then
        debug "Local path does not exist: '${local_path}'."

        return 1
    fi

    remote_user_host="${GLOBALS[REMOTE_USER]}@${GLOBALS[REMOTE_HOST]}"
    remote_path="${GLOBALS[REMOTE_JELLYFIN_DIR]}/${library}"

    debug "Syncing library: '${local_path}/' to '${remote_user_host}:${remote_path}/'."

    #caffeinate -dim \
    #  rsync --devices --specials --ignore-times \
    #  --recursive --times --quiet \
    #  --exclude-from="${GLOBALS[EXCLUDE_FILE]}" \
    #  "${local_path}/" \
    #  "${remote_user_host}:${remote_path}/"

    debug "Done syncing ${library}."
}

main() {
    init_globals

    process_options "$@"

    for library in "${LIBRARIES[@]}"; do
        sync_folders "${library}"
    done
}

main "$@"
