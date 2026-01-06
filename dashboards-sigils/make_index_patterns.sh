#!/usr/bin/env bash

INDEXES=("git*" "github*" "gitlab*")

for index in "${INDEXES[@]}"; do
  echo "Creating index-pattern: $index"

  curl -u admin:GrimoireLab.1 -X POST \
    "http://localhost:5601/api/saved_objects/index-pattern" \
    -H "osd-xsrf: true" \
    -H "Content-Type: application/json" \
    -d "{
      \"attributes\": {
        \"title\": \"$index\"
      }
    }"

  echo
done
