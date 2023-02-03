#!/bin/bash

COMMAND=tagmanager:regenerate-released-containers

if php console --no-ansi list | grep --quiet "$COMMAND"; then
  echo "Starting background regeneration of TagManager containers..."
  while true; do
    php console --no-ansi "$COMMAND" \
      | grep -v '^Done$' \
      | sed -e 's/^/tagmanager-generation: /'
    sleep 60
  done &
fi
