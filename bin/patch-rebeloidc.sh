#!/bin/bash

# RebelOIDC (fork of LoginOIDC) creates rebeloidc_provider with a FK on
# user.login. MySQL 8 fails with error 3780 when collations differ from
# matomo_user.login. Upstream never fixed this in RebelOIDC 5.1.6:
# https://github.com/dominik-th/matomo-plugin-LoginOIDC/issues/91
# https://github.com/dominik-th/matomo-plugin-LoginOIDC/issues/35

set -euo pipefail

rebel_file="${1:-./plugins/RebelOIDC/RebelOIDC.php}"

if [[ ! -f "$rebel_file" ]]; then
  echo "ERROR: $rebel_file not found"
  exit 1
fi

sed -i 's/UNIQUE KEY `user_provider` ( `user`, `provider` ),/UNIQUE KEY `user_provider` ( `user`, `provider` )/' \
  "$rebel_file"
sed -i 's/.*FOREIGN KEY.*ON DELETE CASCADE");/            ");/' "$rebel_file"

if grep -q 'FOREIGN KEY' "$rebel_file"; then
  echo "ERROR: RebelOIDC patch failed, FOREIGN KEY still present in $rebel_file"
  exit 1
fi

if grep -q 'user_provider` ( `user`, `provider` ),' "$rebel_file"; then
  echo "ERROR: RebelOIDC patch failed, trailing comma still present in $rebel_file"
  exit 1
fi

echo "RebelOIDC patch applied to $rebel_file"
