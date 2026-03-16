#!/usr/bin/env bash

set -euxo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <command>" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_dir="$(dirname "$script_dir")"

cd "$app_dir"

bin/configure-environment.sh

exec bash -lc "$*"