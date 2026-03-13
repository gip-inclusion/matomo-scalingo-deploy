#!/bin/bash

echo "Configuring environment..."

bin/generate-config-ini.sh

bin/fetch-purchased-plugins.sh

php console core:clear-caches

php console core:update --yes

php console custom-matomo-js:update

