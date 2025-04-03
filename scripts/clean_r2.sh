#!/usr/bin/env bash

set -e

echo "ALL_FILES: ${ALL_FILES}"
echo "OLD_FILES: ${OLD_FILES}"

for FILE in ${OLD_FILES}; do
  echo "npx wrangler r2 object delete --remote --file ${FILE}"
done
