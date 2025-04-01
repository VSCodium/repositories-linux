#!/usr/bin/env bash

set -e

mkdir -p r2

find pkgs -name '*.deb' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;
find pkgs -name '*.rpm' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;

find r2 -name '*' -type f -exec bash -c 'npx wrangler r2 object put "${R2_BUCKET_NAME}/$( basename "$0" )" -f "$0"'
