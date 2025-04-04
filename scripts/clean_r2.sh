#!/usr/bin/env bash

set -e

echo "ALL_FILES: ${ALL_FILES}"
echo "OLD_FILES: ${OLD_FILES}"

for NAME in ${OLD_FILES}; do
  npx wrangler r2 object delete --remote "${R2_BUCKET_NAME}/${NAME}"

  ALL_FILES="${ALL_FILES//${NAME}/}"
done

# Remove any double spaces that might result from the removal
while [[ "${ALL_FILES}" =~ "  " ]]; do
  ALL_FILES="${ALL_FILES//  / }"
done
# Trim leading and trailing spaces
ALL_FILES="${ALL_FILES#"${ALL_FILES%%[![:space:]]*}"}"
ALL_FILES="${ALL_FILES%"${ALL_FILES##*[![:space:]]}"}"

npx wrangler kv key put --remote --namespace-id="${CLOUDFLARE_KV_NAMESPACE_ID}" "ALL_FILES" "${ALL_FILES}"
