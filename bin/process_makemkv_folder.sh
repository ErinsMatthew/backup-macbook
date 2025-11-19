#!/usr/bin/env bash

set -o nounset

usage() {
    cat << EOT 1>&2
Usage: run_handbrake.sh [-d] [-i input_path] [-o output_path] relative_output_path

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
        [INPUT_EXTENSION]='mkv'                             # -x
        [OUTPUT_EXTENSION]='mkv'                            # -y
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

    while getopts ":di:j:p:o:x:y:" flag; do
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
    printf "%s" "$1" | sed -E "s|^${GLOBALS[BASE_INPUT_PATH]}/(.*)|$2/\1|"
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

run_handbrake() {
    local input_file
    local output_file

    input_file="$1"
    output_file=$(get_output_file "${input_file}")

    if [[ -z ${output_file} ]]; then
        debug "Could not determine output file for input file: '${input_file}'. Skipping."

        return 1
    fi

    if [[ -f ${output_file} ]]; then
        debug "Output file already exists: '${output_file}'. Skipping."

        return 2
    fi

    debug "Processing file: '${input_file}' to '${output_file}'."

    # --json
    caffeinate -dim \
        HandBrakeCLI \
        --preset-import-file "${GLOBALS[PRESET_JSON]}" \
        --preset "${GLOBALS[PRESET_NAME]}" \
        --input "${input_file}" \
        --output "${output_file}"

    debug "Done with file: '${input_file}'."
}


main() {
    init_globals

    process_options "$@"

    set_defaults

    validate_globals

    while read -r file; do
        run_handbrake "${file}"
    done < <(gfind "${GLOBALS[BASE_INPUT_PATH]}" -type f -name "*.${GLOBALS[INPUT_EXTENSION]}")
}

main "$@"
