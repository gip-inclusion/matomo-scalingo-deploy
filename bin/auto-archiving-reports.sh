#!/bin/bash

set -e
set -o pipefail

if [[ -z "$MATOMO_AUTO_ARCHIVING_FREQUENCY" ]]; then
  echo "Auto-archiving reports job disabled"
else
  bin/configure-environment.sh

  echo "Start auto-archiving reports job"
  echo "Archiving reports... "
  php console core:archive --skip-segments-today
  echo "done"
fi