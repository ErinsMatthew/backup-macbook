#!/usr/bin/env bash

set -o nounset

# run summary on exit or interrupt
trap summary EXIT

usage() {
    cat << EOT 1>&2
Usage: backup_makemkv_folder.sh [-d] [-i input_path] [-o output_path]

OPTIONS
=======
-d      output debug information
-i dir  input path for the source files
-o dir  output path for the processed files

EXAMPLE
=======
$ backup_makemkv_folder.sh -d -i /Users/doof/MakeMKV\ Working\ Folder/ -o /Volumes/Jellyfin\ Media\ MKV\ Backup

EOT

  exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'                                     # -d
        [BASE_INPUT_PATH]=''                                # -i
        [BASE_OUTPUT_PATH]=''                               # -o
        [IMDB_DB_PATH]='/Users/doof/Documents/imdb.db'
        [START_TIME]=0
    )

    declare -ag SHORT_FILES=()

    declare -Ag COUNTS=(
        [PROCESSED]=0
        [EXISTS]=0
        [ERROR]=0
    )

    declare -Ag COLORS=(
        [bold]=$(tput bold)
        [blue]=$(tput setaf 4)
        [green]=$(tput setaf 2)
        [red]=$(tput setaf 1)
        [white]=$(tput setaf 7)
        [reset]=$(tput sgr0)
    )
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

    while getopts ":di:o:" flag; do
        case "${flag}" in
            d)
                GLOBALS[DEBUG]='true'

                debug "Debug mode turned on."
                ;;

            i)
                GLOBALS[BASE_INPUT_PATH]=$(realpath "${OPTARG}")

                debug "Input path set to '${GLOBALS[BASE_INPUT_PATH]}'."
                ;;

            o)
                GLOBALS[BASE_OUTPUT_PATH]=$(realpath "${OPTARG}")

                debug "Output path set to '${GLOBALS[BASE_OUTPUT_PATH]}'."
                ;;

            *)
                usage
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))
}

check_for_dependency() {
    debug "Checking for dependency '$1'."

    if ! command -v "$1" &> /dev/null; then
        echo "Dependency '$1' is missing." > /dev/stderr

        exit
    fi
}

check_dependencies() {
    local dependency

    for dependency in caffeinate cat date ffprobe gsed realpath sed sqlite-utils tput; do
        check_for_dependency "${dependency}"
    done
}

validate_globals() {
    if [[ ! -d ${GLOBALS[BASE_INPUT_PATH]} ]]; then
        debug "Error: Input path is valid."

        usage
    fi

    if [[ ! -d ${GLOBALS[BASE_OUTPUT_PATH]} ]]; then
        debug "Error: Output path is not valid."

        usage
    fi
}

get_movie_or_show_name() {
    printf "%s" "$1" | sed -E "s|^${GLOBALS[BASE_INPUT_PATH]}/(.*)/.*|\1|"
}

get_movie_or_show_id() {
    printf "%s" "$1" | sed -E "s|^${GLOBALS[BASE_INPUT_PATH]}/.* \[imdbid-(.*)\]/.*|\1|"
}

replace_input_path() {
    printf "%s" "$1" | sed -E "s|^${GLOBALS[BASE_INPUT_PATH]}/(.*)|$2/\1|"
}

get_title_type() {
    sqlite-utils "${GLOBALS[IMDB_DB_PATH]}" \
      'SELECT m.mappedTitleType || "s" FROM title_basics AS t, title_type_map AS m WHERE t.titleType = m.titleType AND t.tconst = :tconst;' \
      -p tconst "$1" \
      -r | gsed -e 's/\b\(.\)/\u\1/g'
}

get_output_file() {
    local input_file
    local show_or_movie_name
    local output_file

    input_file="$1"

    show_or_movie_id=$(get_movie_or_show_id "${input_file}")

    if [[ -z ${show_or_movie_id} ]]; then
        debug "Could not extract show or movie ID from input file: '${input_file}'."

        return 1
    fi

    type=$(get_title_type "${show_or_movie_id}")

    output_file=$(replace_input_path "${input_file}" "${GLOBALS[BASE_OUTPUT_PATH]}/${type}")

    printf "%s" "${output_file}"
}

get_file_seconds() {
    local seconds

    seconds=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
    seconds=${seconds%.*}

    printf "%s" "${seconds}"
}

backup_file() {
    local input_file
    local output_file
    local show_or_movie_name

    input_file="$1"
    output_file=$(get_output_file "${input_file}")
    show_or_movie_name=$(get_movie_or_show_name "${input_file}")

    if [[ -z ${output_file} ]]; then
        debug "Could not determine output file for input file: '${input_file}'. Skipping."

        COUNTS[ERROR]=$((COUNTS[ERROR] + 1))

        return 1
    fi

    if [[ -f ${output_file} ]]; then
        debug "${COLORS[bold]}${COLORS[green]}${show_or_movie_name}: ${COLORS[red]}Output file already exists:${COLORS[reset]} '${output_file}'. Skipping."

        COUNTS[EXISTS]=$((COUNTS[EXISTS] + 1))

        local input_seconds
        local output_seconds

        input_seconds=$(get_file_seconds "${input_file}")
        output_seconds=$(get_file_seconds "${output_file}")

        if (( output_seconds < input_seconds )); then
            debug "Output file '${output_file}' is possibly shorter than '${input_file}'."

            SHORT_FILES+=("${input_file} (${input_seconds}s) vs ${output_file} (${output_seconds}s)")
        fi

        return 2
    fi

    debug "Backing up file: '${input_file}' to '${output_file}'."

    # make directory if it doesn't exist
    mkdir -p "$(dirname "${output_file}")"

    cp "${input_file}" "${output_file}"

    debug "Done with file: '${input_file}'."

    COUNTS[PROCESSED]=$((COUNTS[PROCESSED] + 1))
}

summary() {
    local end_time
    local elapsed
    local duration

    end_time=$(date +%s)
    elapsed=$((end_time - GLOBALS[START_TIME]))
    duration=$(date -ud "@$elapsed" +'%H hr %M min %S sec')

    cat <<EOT

Processing complete.

${COLORS[white]}== ${COLORS[blue]}TIMING ${COLORS[white]}==${COLORS[reset]}
Start Time : ${GLOBALS[START_TIME]}
End Time   : ${end_time}
Duration   : ${duration}

${COLORS[white]}== ${COLORS[blue]}COUNTS ${COLORS[white]}==${COLORS[reset]}
Processed : ${COUNTS[PROCESSED]}
Exists    : ${COUNTS[EXISTS]}
Errors    : ${COLORS[red]}${COUNTS[ERROR]}${COLORS[reset]}

${COLORS[white]}== ${COLORS[red]}MISMATCHES ${COLORS[white]}==${COLORS[reset]}
${SHORT_FILES[@]}
EOT

    exit
}

main() {
    init_globals

    process_options "$@"

    check_dependencies

    validate_globals

    mapfile -d $'\0' file_list < <(gfind "${GLOBALS[BASE_INPUT_PATH]}" -type f ! -name '.DS_Store' -print0)

    GLOBALS[START_TIME]=$(date +%s)

    for file in "${file_list[@]}"; do
        backup_file "${file}"
    done
}

main "$@"
