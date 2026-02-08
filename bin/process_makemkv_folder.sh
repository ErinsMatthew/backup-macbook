#!/usr/bin/env bash

set -o nounset

# run summary on exit or interrupt
trap summary EXIT

usage() {
    cat << EOT 1>&2
Usage: process_makemkv_folder.sh [-d] [-i input_path] [-o output_path] relative_output_path

 OPTIONS
 =======
 -d        output debug information
 -i dir    input path for the source files
 -j file   HandBrake preset JSON file
 -p name   HandBrake preset name
 -o dir    output path for the processed files
 -x ext    input file extension (default: mkv)
 -y ext    output file extension (default: mkv)

EOT

  exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'                                     # -d
        [BASE_INPUT_PATH]=''                                # -i
        [PRESET_JSON]=''                                    # -j
        [PRESET_NAME]='MKV Fast 1080p30 English Subtitles'  # -p
        [BASE_OUTPUT_PATH]=''                               # -o
        [THREAD_COUNT]=$(sysctl -n hw.ncpu)                 # -t
        [INPUT_EXTENSION]='mkv'                             # -x
        [OUTPUT_EXTENSION]='mkv'                            # -y
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

    while getopts ":di:j:p:o:t:x:y:" flag; do
        case "${flag}" in
            d)
                GLOBALS[DEBUG]='true'

                debug "Debug mode turned on."
                ;;

            i)
                GLOBALS[BASE_INPUT_PATH]=$(realpath "${OPTARG}")

                debug "Input path set to '${GLOBALS[BASE_INPUT_PATH]}'."
                ;;

            j)
                GLOBALS[PRESET_JSON]="${OPTARG}"

                debug "Preset JSON file set to '${GLOBALS[PRESET_JSON]}'."
                ;;

            p)
                GLOBALS[PRESET_NAME]="${OPTARG}"

                debug "Preset name set to '${GLOBALS[PRESET_NAME]}'."
                ;;

            o)
                GLOBALS[BASE_OUTPUT_PATH]=$(realpath "${OPTARG}")

                debug "Output path set to '${GLOBALS[BASE_OUTPUT_PATH]}'."
                ;;

            t)
                local cpu_count

                cpu_count=$(sysctl -n hw.ncpu)

                if (( OPTARG < 1 || OPTARG > cpu_count )); then
                    debug "Thread count must be between 1 and ${cpu_count}."

                    usage
                fi

                GLOBALS[THREAD_COUNT]="${OPTARG}"

                debug "Thread count set to '${GLOBALS[THREAD_COUNT]}'."
                ;;

            x)
                GLOBALS[INPUT_EXTENSION]=$(realpath "${OPTARG}")

                debug "Input extension set to '${GLOBALS[INPUT_EXTENSION]}'."
                ;;

            y)
                GLOBALS[OUTPUT_EXTENSION]=$(realpath "${OPTARG}")

                debug "Output extension set to '${GLOBALS[OUTPUT_EXTENSION]}'."
                ;;

            *)
                usage
                ;;
        esac
    done

    shift $(( OPTIND - 1 ))
}

set_defaults() {
    if [[ -z ${GLOBALS[PRESET_JSON]} ]]; then
        GLOBALS[PRESET_JSON]=$(realpath ./handbrake_presets.json)

        debug "Preset JSON file set to default of '${GLOBALS[PRESET_JSON]}'."
    fi
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

    for dependency in caffeinate cat date ffprobe HandBrakeCLI realpath sed tput; do
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

replace_input_path() {
    printf "%s" "$1" | sed -E "s|^${GLOBALS[BASE_INPUT_PATH]}/(.*)\.${GLOBALS[INPUT_EXTENSION]}|$2/\1.${GLOBALS[OUTPUT_EXTENSION]}|"
}

get_output_file() {
    local input_file
    local show_or_movie_name
    local output_file

    input_file="$1"

    show_or_movie_name=$(get_movie_or_show_name "${input_file}")

    for type in "movies" "shows"; do
        if [[ -d "${GLOBALS[BASE_OUTPUT_PATH]}/${type}/${show_or_movie_name}" ]]; then
            output_file=$(replace_input_path "${input_file}" "${GLOBALS[BASE_OUTPUT_PATH]}/${type}")
        fi
    done

    printf "%s" "${output_file}"
}

get_file_seconds() {
    local seconds

    seconds=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
    seconds=${seconds%.*}

    printf "%s" "${seconds}"
}

run_handbrake() {
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

    debug "Processing file: '${input_file}' to '${output_file}'."

    caffeinate -dim \
        HandBrakeCLI \
        --preset-import-file "${GLOBALS[PRESET_JSON]}" \
        --preset "${GLOBALS[PRESET_NAME]}" \
        --input "${input_file}" \
        --output "${output_file}" \
        -x threads="${GLOBALS[THREAD_COUNT]}"

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

    set_defaults

    validate_globals

    mapfile -d $'\0' file_list < <(gfind "${GLOBALS[BASE_INPUT_PATH]}" -type f -name "*.${GLOBALS[INPUT_EXTENSION]}" -print0)

    GLOBALS[START_TIME]=$(date +%s)

    for file in "${file_list[@]}"; do
        run_handbrake "${file}"
    done
}

main "$@"
