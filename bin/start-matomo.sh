#!/bin/bash

echo "Starting Matomo application..."

bin/configure-environment.sh

bin/set-matomo-nginx.sh

bin/start-tagmanager-generation.sh

touch /tmp/matomo.log
tail -n 0 -qF --pid=$$ /tmp/matomo.log 2>&1 &

exec bash bin/run
