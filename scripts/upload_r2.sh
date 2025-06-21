#!/usr/bin/env bash

set -e
set -o pipefail

shopt -s globstar

mkdir -p r2

REDIRECTS=""

pushd pkgs > /dev/null

for FILE in **/*.[dr][ep][bm]; do
  if [[ "${FILE}" == *.deb || "${FILE}" == *.rpm ]]; then
    NAME=$( basename "${FILE}" )

    REDIRECTS="${REDIRECTS}"$'\n'"${FILE} ${R2_BUCKET_URL}/${NAME} 302"

    mv "${FILE}" ../r2
  fi
done

popd > /dev/null

echo "${REDIRECTS}" > _site/_redirects

ALL_FILES=$( npx wrangler kv key get --remote --namespace-id="${CLOUDFLARE_KV_NAMESPACE_ID}" "ALL_FILES" )
OLD_FILES="${ALL_FILES}"

echo "ALL_FILES: ${ALL_FILES}"

for FILE in r2/*; do
  if [[ -f "${FILE}" ]]; then
    NAME=$( basename "${FILE}" )

    npx wrangler r2 object put --remote --file "${FILE}" "${R2_BUCKET_NAME}/${NAME}" | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/****/g'

    if [[ "${ALL_FILES}" == *"${NAME}"* ]]; then
      OLD_FILES="${OLD_FILES//${NAME}/}"
    else
      ALL_FILES="${ALL_FILES} ${NAME}"
    fi
  fi
done

echo "ALL_FILES: ${ALL_FILES}"

npx wrangler kv key put --remote --namespace-id="${CLOUDFLARE_KV_NAMESPACE_ID}" "ALL_FILES" "${ALL_FILES}"

echo "ALL_FILES=${ALL_FILES}" >> "${GITHUB_ENV}"
echo "OLD_FILES=${OLD_FILES}" >> "${GITHUB_ENV}"
