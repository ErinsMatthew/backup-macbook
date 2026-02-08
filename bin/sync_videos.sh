#!/usr/bin/env bash


ICLOUD_DIR='/Users/doof/iCloud/Videos'
GDRIVE_DIR='/Volumes/G-DRIVE ArmorATD'

MAX_ITERATIONS=5

if [[ ! -d ${GDRIVE_DIR} ]]; then
    printf "ERROR: %s is not a valid directory.\n" "${GDRIVE_DIR}"

    exit -1
fi

declare -i counter

counter=0

while IFS= read -r line; do
    printf "Processing %s\n" "${line}"

    ICLOUD_FILE_NAME=$(realpath "${ICLOUD_DIR}/${line}")
    GDRIVE_FILE_NAME=$(realpath "${GDRIVE_DIR}")/${line}
    GDRIVE_DIR_NAME=$(dirname "${GDRIVE_FILE_NAME}")

    printf "\tICLOUD_FILE_NAME = %s\n\tGDRIVE_FILE_NAME = %s\n" "${ICLOUD_FILE_NAME}" "${GDRIVE_FILE_NAME}"

    if [[ ! -f ${ICLOUD_FILE_NAME} ]]; then
        printf "\tSource file not found = %s\n" "${ICLOUD_FILE_NAME}"

        continue
    fi

    if [[ -f ${GDRIVE_FILE_NAME} ]]; then
        printf "\tDestination file alredy exists = %s\n" "${ICLOUD_FILE_NAME}"

        continue
    fi

    if [[ ! -d ${GDRIVE_DIR_NAME} ]]; then
        printf "\tDestination directory does not exist = %s\n" "${GDRIVE_DIR_NAME}"

        mkdir -p "${GDRIVE_DIR_NAME}"
    fi

    brctl download "${ICLOUD_FILE_NAME}"

    cp "${ICLOUD_FILE_NAME}" "${GDRIVE_FILE_NAME}"

    brctl evict "${ICLOUD_FILE_NAME}"

    counter=$(( counter++ ))

    if [[ $counter -gt $MAX_ITERATIONS ]]; then
        break
    fi

    sleep 15
done < "$1"
