#!/usr/bin/env bash

set -e

npx wrangler pages deploy _site --project-name="${PAGE_NAME}"

DEPLOYMENTS=$( curl -s \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${PAGE_NAME}/deployments" )

echo "${DEPLOYMENTS}" | jq -e '.success' >/dev/null || {
    echo "Failed to fetch deployments"
    echo "Error: $(echo "${DEPLOYMENTS}" | jq -r '.errors[].message')"
    exit 1
}

readarray -t DEPLOYMENTS_TO_DELETE < <( echo "${DEPLOYMENTS}" | jq -r '.result | sort_by(.created_on) | reverse | .[3:] | .[].id' )

echo "Found ${#DEPLOYMENTS_TO_DELETE[@]} deployments to delete"

for DEPLOYMENT_ID in "${DEPLOYMENTS_TO_DELETE[@]}"; do
  if [ -n "${DEPLOYMENT_ID}" ]; then
    echo "Deleting deployment: ${DEPLOYMENT_ID}"

    RESPONSE=$( curl -X DELETE \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${PAGE_NAME}/deployments/${DEPLOYMENT_ID}" )

    # Check if deletion was successful
    if echo "${RESPONSE}" | jq -e '.success' >/dev/null; then
      echo "Successfully deleted deployment: ${DEPLOYMENT_ID}"
    else
      echo "Failed to delete deployment: ${DEPLOYMENT_ID}"
      ERROR_MESSAGE=$(echo "${RESPONSE}" | jq -r '.errors[].message')
      echo "Error: ${ERROR_MESSAGE}"
      exit 1
    fi
  fi
done

