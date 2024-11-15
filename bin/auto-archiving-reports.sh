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
    php console core:archive
    echo "done"
    sleep "$MATOMO_AUTO_ARCHIVING_FREQUENCY"
  done
fi
