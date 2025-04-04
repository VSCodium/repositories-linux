#!/usr/bin/env bash

set -e

echo "ALL_FILES: ${ALL_FILES}"
echo "OLD_FILES: ${OLD_FILES}"

for FILE in ${OLD_FILES}; do
  npx wrangler r2 object delete --remote --file "${FILE}"

  ALL_FILES="${ALL_FILES//${FILE}/}"
done

# Remove any double spaces that might result from the removal
ALL_FILES="${ALL_FILES//  / }"
# Trim leading and trailing spaces
ALL_FILES="${ALL_FILES#"${ALL_FILES%%[![:space:]]*}"}"
ALL_FILES="${ALL_FILES%"${ALL_FILES##*[![:space:]]}"}"

npx wrangler kv key put --remote --namespace-id="${CLOUDFLARE_KV_NAMESPACE_ID}" "ALL_FILES" "${ALL_FILES}"
