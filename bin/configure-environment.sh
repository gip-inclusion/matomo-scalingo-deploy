#!/bin/bash

set -euo pipefail

bin/fetch-purchased-plugins.sh
bin/generate-config-ini.sh
php console custom-matomo-js:update
php console core:clear-caches
php console core:update --yes
for plugin in RebelOIDC ForceOIDCLogin AbTesting FormAnalytics Funnels HeatmapSessionRecording MediaAnalytics QueuedTracking; do
  [ -d "./plugins/$plugin" ] && php console plugin:install "$plugin" --yes
done
