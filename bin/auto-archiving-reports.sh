#!/bin/bash

set -e
set -o pipefail

if [[ -z "$MATOMO_AUTO_ARCHIVING_FREQUENCY" ]]; then
  echo "Auto-archiving reports job disabled"
else
  bin/fetch-purchased-plugins.sh
  bin/generate-config-ini.sh
  bin/set-license-key.sh

  echo "Start auto-archiving reports CRON job"
  while true; do
    echo "Archiving reports... "
    if [[ -n "$MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT" ]]; then
      php -d memory_limit="${MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT}M" console core:archive --php-cli-options="-d memory_limit=${MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT}M"
    else
      php console core:archive
    fi
    echo "done"
    sleep "$MATOMO_AUTO_ARCHIVING_FREQUENCY"
  done
fi
