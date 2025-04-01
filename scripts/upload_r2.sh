#!/usr/bin/env bash

set -ex

mkdir -p r2

find pkgs -name '*.deb' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;
find pkgs -name '*.rpm' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;

# find r2 -type f -exec bash -c 'npx wrangler r2 object put --remote --file "$0" "${R2_BUCKET_NAME}/$( basename "$0" )" || exit 1' {} \;
for FILE in r2/*; do
  if [[ -f "${FILE}" ]]; then
    npx wrangler r2 object put --remote --file "${FILE}" "${R2_BUCKET_NAME}/$(basename "${FILE}")"
  fi
done
