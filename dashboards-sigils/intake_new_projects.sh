#!/usr/bin/env bash

PATH_FROM_ROOT="/open-pulse/open-pulse-grimoirelab/"

WATCHED_FILE="${PATH_FROM_ROOT}default-grimoirelab-settings/projects.json"
STATE_FILE="${PATH_FROM_ROOT}tmp/projects_file_checksum_mordred"

# 1. Check watch file existence and initialize the state file 
if [ ! -f "$WATCHED_FILE" ]; then
    echo "The file you want to watch or is being watched does not exist: $WATCHED_FILE"
    exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
    echo "$CURRENT_SUM" > "$STATE_FILE"
    exit 0
fi

# 2. Git pull to see catch the new version of the file
if ! git -C "$PATH_FROM_ROOT" pull --quiet; then
    echo "Git pull failed in $PATH_FROM_ROOT"
    exit 1
fi

# 3. Compare SHA signatures of the file to see if there have been any changes
# if changes mordred needs to be restarted
CURRENT_SUM=$(sha256sum "$WATCHED_FILE" | awk '{print $1}')
PREVIOUS_SUM=$(cat "$STATE_FILE")

if [ "$CURRENT_SUM" != "$PREVIOUS_SUM" ]; then
    echo "Projects file changed. Restarting docker compose for mordred..."

    docker compose -p docker-compose-mordred-1 restart

    echo "$CURRENT_SUM" > "$STATE_FILE"
fi
