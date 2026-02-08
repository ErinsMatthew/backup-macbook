#!/usr/bin/env bash


FOLLOWERS_JSON='/Users/doof/Downloads/connections/followers_and_following/following.json'
LIKED_POSTS_JSON='/Users/doof/Downloads/your_instagram_activity/likes/liked_posts.json'
EXCLUSIONS_FILE='/Users/doof/bin/likes_by_creator_exclusions.txt'
OUTPUT_CSV='/Users/doof/tmp/likes.csv'


FOLLOWERS_TEMP_FILE=$(mktemp) || exit 1
EXCLUSIONS_TEMP_FILE=$(mktemp) || exit 1

jq --raw-output '.relationships_following[] | .title' "${FOLLOWERS_JSON}" > "${FOLLOWERS_TEMP_FILE}"

cat "${EXCLUSIONS_FILE}" >> "${FOLLOWERS_TEMP_FILE}"
sort "${FOLLOWERS_TEMP_FILE}" | uniq > "${EXCLUSIONS_TEMP_FILE}"


jq --raw-output '.likes_media_likes | group_by(.title) | map({"title": .[0].title, "count": length}) | sort_by(-.count)[] | select( all( .; .count > 4) ) | [.title, .count] | @csv' "${LIKED_POSTS_JSON}" | grep -v -f "${EXCLUSIONS_TEMP_FILE}" > "${OUTPUT_CSV}"
