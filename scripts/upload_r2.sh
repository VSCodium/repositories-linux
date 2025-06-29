#!/usr/bin/env bash

set -e

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

set +e

for FILE in r2/*; do
  if [[ -f "${FILE}" ]]; then
    NAME=$( basename "${FILE}" )

    for i in {1..5}; do # try 5 times
      echo "$( date +"%H:%M:%S" ) @ Uploading ${NAME}..."

      # Run wrangler and mask sensitive output if needed
      OUTPUT=$( npx wrangler r2 object put --remote --file "${FILE}" "${R2_BUCKET_NAME}/${NAME}" 2>&1 )
      MASKED_OUTPUT=$( echo "${OUTPUT}" | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/****/g' )

      echo "${MASKED_OUTPUT}"

      # Look for log file
      # LOG_FILE=$(echo "$MASKED_OUTPUT" | sed -n 's/.*Logs were written to "\([^"]*\)".*/\1/p')

      # if [[ -n "$LOG_FILE" ]]; then
      #   echo "==== Log file: $LOG_FILE ===="
      #   cat "$LOG_FILE" | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/****/g'

      #   exit 1
      # fi

      if [[ "${MASKED_OUTPUT}" != *"ERROR"* ]]; then
        break
      fi

      if [[ $i == 5 ]]; then
        echo "$( date +"%H:%M:%S" ) @ Upload ${NAME} failed too many times" >&2
        exit 1
      fi

      echo "$( date +"%H:%M:%S" ) @ Upload ${NAME} failed $i, trying again..."

      sleep $(( 15 * (i + 1)))
    done

    if [[ "${ALL_FILES}" == *"${NAME}"* ]]; then
      OLD_FILES="${OLD_FILES//${NAME}/}"
    else
      ALL_FILES="${ALL_FILES} ${NAME}"
    fi
  fi
done

set -e

echo "ALL_FILES: ${ALL_FILES}"

npx wrangler kv key put --remote --namespace-id="${CLOUDFLARE_KV_NAMESPACE_ID}" "ALL_FILES" "${ALL_FILES}"

echo "ALL_FILES=${ALL_FILES}" >> "${GITHUB_ENV}"
echo "OLD_FILES=${OLD_FILES}" >> "${GITHUB_ENV}"
