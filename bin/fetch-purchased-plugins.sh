#!/bin/bash

PURCHASED_PLUGINS=(
  "QueuedTracking:5.2.0"
  "HeatmapSessionRecording:5.3.3"
  "FormAnalytics:5.1.3"
  "AbTesting:5.5.1"
  "MediaAnalytics:5.0.13"
  "Funnels:5.3.12"
)

FREE_PLUGINS=(
  "RebelOIDC:5.1.6"
)

download_plugin() {
  local plugin_name=$1
  local plugin_version=$2
  local access_token=$3
  local plugins_dir=$4
  local zip_file_location="$plugins_dir/$plugin_name.zip"
  local url="https://plugins.matomo.org/api/2.0/plugins/$plugin_name/download/$plugin_version"

  rm -rf "$plugins_dir/$plugin_name"
  rm -f "$zip_file_location"
  echo "Downloading plugin $plugin_name#$plugin_version at $url"
  if [[ -n "$access_token" ]]; then
    curl -s -X POST -F "access_token=$access_token" -L "${url}" -o "$zip_file_location"
  else
    curl -s -L "${url}" -o "$zip_file_location"
  fi

  echo "Unzipping $zip_file_location to $plugins_dir/$plugin_name"
  unzip -qo "$zip_file_location" -d "$plugins_dir"
}

echo "Fetching Matomo plugins..."

plugins_dir="./plugins"
mkdir -p "${PWD}/$plugins_dir"

for plugin in "${FREE_PLUGINS[@]}"; do
  download_plugin "${plugin%%:*}" "${plugin##*:}" "" "$plugins_dir"
done

if [[ -z "$MATOMO_LICENSE_KEY" ]]; then
  echo "Skipping purchased plugins: no MATOMO_LICENSE_KEY defined"
else
  for plugin in "${PURCHASED_PLUGINS[@]}"; do
    download_plugin "${plugin%%:*}" "${plugin##*:}" "$MATOMO_LICENSE_KEY" "$plugins_dir"
  done
fi
