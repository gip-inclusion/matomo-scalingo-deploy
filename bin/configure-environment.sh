#!/bin/bash

echo "Configuring environment..."

bin/fetch-purchased-plugins.sh

bin/generate-config-ini.sh

bin/set-license-key.sh
