#!/usr/bin/env bash

set -o nounset

usage() {
    cat << EOT 1>&2
Usage: run_handbrake.sh [-d] [-i input_path] [-o output_path] relative_output_path

 OPTIONS
 =======
 -d        output debug information
 -i        input path for the media files
 -o        output path for the processed files

EOT

  exit
}

init_globals() {
    declare -Ag GLOBALS=(
        [DEBUG]='false'
        [BASE_INPUT_PATH]=''
        [BASE_OUTPUT_PATH]=''
        [PRESET_JSON]=''
        [PRESET_NAME]='MKV Fast 1080p30 English Subtitles'
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

    while getopts ":di:o:j:p:" flag; do
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

            j)
                GLOBALS[PRESET_JSON]="${OPTARG}"

                debug "Preset JSON file set to '${GLOBALS[PRESET_JSON]}'."
                ;;

            p)
                GLOBALS[PRESET_NAME]="${OPTARG}"

                debug "Preset name set to '${GLOBALS[PRESET_NAME]}'."
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

run_handbrake() {
    local input_path
    local output_path

    input_path="${GLOBALS[BASE_INPUT_PATH]}"
    output_path="${GLOBALS[BASE_OUTPUT_PATH]}"

    if [[ ! -d ${input_path} ]]; then
        debug "Local path does not exist: '${input_path}'."

        return 1
    fi

    if [[ ! -d ${output_path} ]]; then
        debug "Local path does not exist: '${output_path}'."

        return 1
    fi

    debug "Running HandBrake on files in '${input_path}'..."

    for input_file in "${input_path}"/*.mkv; do
        if [[ ! -f ${input_file} ]]; then
            debug "Skipping non-file: '${input_file}'."

            continue
        fi

        local filename
        local output_file

        filename=$(basename "${input_file}")
        output_file="${output_path}/${filename%.*}.mkv"

        if [[ -f ${output_file} ]]; then
            debug "Output file already exists, skipping: '${output_file}'."

            continue
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
    done

    debug "Done."
}

main() {
    init_globals

    process_options "$@"

    set_defaults

    run_handbrake
}

main "$@"
