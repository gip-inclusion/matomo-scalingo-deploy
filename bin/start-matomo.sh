#!/bin/bash

echo "Starting Matomo application..."

bin/fetch-purchased-plugins.sh

bin/generate-config-ini.sh

bin/set-license-key.sh

bin/activate-plugins.sh

bin/set-matomo-nginx.sh

touch /tmp/matomo.log && tail -F /tmp/matomo.log &

exec bash bin/run
