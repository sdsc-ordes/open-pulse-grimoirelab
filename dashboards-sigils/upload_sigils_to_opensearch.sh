#!/usr/bin/env bash

SIGILS_DIR="./sigils"

# Exit if sigils directory does not exist
if [[ ! -d "$SIGILS_DIR" ]]; then
  echo "Error: sigils directory not found"
  exit 1
fi

shopt -s nullglob

for file in "$SIGILS_DIR"/*.ndjson; do
  echo "Importing: $file"

  curl -u admin:GrimoireLab.1 -X POST \
    "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
    -H "osd-xsrf:true" \
    --form "file=@${file}"

  echo
done
