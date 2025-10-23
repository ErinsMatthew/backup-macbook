#!/usr/bin/env bash

set -o nounset

MKV_WORKING_FOLDER="/Users/doof/MakeMKV Working Folder"
MP4_WORKING_FOLDER="/Users/doof/Jellyfin"

mkv_working_folder_basename=$(basename "${MKV_WORKING_FOLDER}")

get_mp4_base_folder() {
    local mp4_base_folder=""

    if [[ -d "${MP4_WORKING_FOLDER}/movies/$1" ]]; then
        mp4_base_folder="${MP4_WORKING_FOLDER}/movies"
    elif [[ -d "${MP4_WORKING_FOLDER}/shows/$1" ]]; then
        mp4_base_folder="${MP4_WORKING_FOLDER}/shows"
    else
        echo "Error: MP4 working folder for '$1' / '${MP4_WORKING_FOLDER}' does not exist." 1>&2

        exit 1
    fi

    printf "%s\n" "${mp4_base_folder}"
}

get_file_count() {
    local folder="$1"
    local extension="$2"

    find "${folder}" -maxdepth 1 -type f -name "*.${extension}" | wc -l
}

process_directory() {
    local dir="$1"
    local mp4_base_folder="$2"

    mkv_file_count=$(get_file_count "${MKV_WORKING_FOLDER}/${dir}" "mkv")

    if [ "${mkv_file_count}" -gt 0 ]; then
        mp4_file_count=$(get_file_count "${mp4_base_folder}/${dir}" "mp4")

        if [ "${mp4_file_count}" -lt "${mkv_file_count}" ]; then
            printf "%s: MKV = %d, MP4 = %d\n" "${dir}" "${mkv_file_count}" "${mp4_file_count}"

            source ./run_handbrake.sh -i "${MKV_WORKING_FOLDER}/${dir}/" -o "${mp4_base_folder}/${dir}/"
        fi
    fi
}

while read -r dir; do
    if [ "${dir}" == "." ] || [ "${dir}" == ".." ] || [ "${dir}" == "${mkv_working_folder_basename}" ]; then
        continue
    fi

    mp4_base_folder=$(get_mp4_base_folder "${dir}")

    for subdir in "${dir}" "${dir}/extras"; do
        process_directory "${subdir}" "${mp4_base_folder}"
    done

    while read -r subdir; do
        process_directory "${dir}/${subdir}" "${mp4_base_folder}"
    done < <(gfind "${MKV_WORKING_FOLDER}/${dir}" -maxdepth 1 -type d -name "Season *" -printf "%f\n")
done < <(gfind "${MKV_WORKING_FOLDER}" -maxdepth 1 -type d -printf "%f\n")
