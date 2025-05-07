#!/bin/bash

set -e
set -o pipefail

if [[ -z "$MATOMO_AUTO_ARCHIVING_FREQUENCY" ]]; then
  echo "Auto-archiving reports job disabled"
else
  bin/configure-environment.sh

  echo "Start auto-archiving reports job"
  echo "Archiving reports... "
  if [[ -n "$MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT" ]]; then
    php -d memory_limit="${MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT}" console core:archive --skip-segments-today --php-cli-options="-d memory_limit=${MATOMO_AUTO_ARCHIVING_MEMORY_LIMIT}"
  else
    php console core:archive --skip-segments-today
  fi
  echo "done"
fi