#!/bin/bash

echo "Starting Matomo application..."

bin/fetch-purchased-plugins.sh

bin/generate-config-ini.sh

bin/set-license-key.sh

bin/set-matomo-nginx.sh

bin/start-tagmanager-generation.sh

touch /tmp/matomo.log
tail -n 0 -qF --pid=$$ /tmp/matomo.log 2>&1 &

exec bash bin/run
