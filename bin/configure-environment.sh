#!/bin/bash

echo "Configuring environment..."

bin/fetch-purchased-plugins.sh

bin/generate-config-ini.sh

php console custom-matomo-js:update

