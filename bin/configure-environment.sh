#!/bin/bash

echo "Configuring environment..."

bin/fetch-purchased-plugins.sh

bin/generate-config-ini.sh

php console core:clear-caches

php console core:update --yes

php console custom-matomo-js:update

