#!/usr/bin/env bash

set -e

mkdir -p r2

find pkgs -name '*.deb' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;
find pkgs -name '*.rpm' -exec bash -c 'mv "$0" "r2/$( basename "$0" )"' {} \;

ALL_FILES=$( npx wrangler kv key get --remote --binding="KV_REPO" "ALL_FILES" )
OLD_FILES="${ALL_FILES}"

for FILE in r2/*; do
  if [[ -f "${FILE}" ]]; then
    NAME=$( basename "${FILE}" )

    npx wrangler r2 object put --remote --file "${FILE}" "${R2_BUCKET_NAME}/${NAME}" | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/****/g'

    if [[ "${ALL_FILES}" == *"${NAME}"* ]]; then
      OLD_FILES="${ALL_FILES//${NAME}/}"
    else
      ALL_FILES="${ALL_FILES} ${NAME}"
    fi
  fi
done

npx wrangler kv key put --remote --binding="KV_REPO" "ALL_FILES" "${ALL_FILES}"

echo "ALL_FILES=${ALL_FILES}" >> "${GITHUB_ENV}"
echo "OLD_FILES=${OLD_FILES}" >> "${GITHUB_ENV}"
