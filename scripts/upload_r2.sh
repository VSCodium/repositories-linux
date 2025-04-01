#!/usr/bin/env bash

set -e

mkdir -p r2

find pkgs -name '*.deb' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;
find pkgs -name '*.rpm' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;

for FILE in r2/*; do
  if [[ -f "${FILE}" ]]; then
    npx wrangler r2 object put --remote --file "${FILE}" "${R2_BUCKET_NAME}/$(basename "${FILE}")" | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/****/g'
  fi
done
