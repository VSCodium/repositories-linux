#!/usr/bin/env bash

set -e

if [[ "${CI}" != "true" ]]; then
  . ./.env
fi

npm ci

rm -rf _site _pages _components

# generate context.json
JSON_DATA=$( jq \
  --arg gpg_fingerprint "${GPG_FINGERPRINT}" \
  --arg package_name    "${PACKAGE_NAME}" \
  --arg project_name    "${PROJECT_NAME}" \
  --arg project_url     "${PROJECT_URL}" \
  --arg r2_bucket_name  "${R2_BUCKET_NAME}" \
  --arg r2_bucket_url   "${R2_BUCKET_URL}" \
  --arg repo_arch_deb   "${REPO_ARCH_DEB}" \
  --arg repo_arch_rpm   "${REPO_ARCH_RPM}" \
  --arg repo_name       "${REPO_NAME}" \
  --arg repo_url        "${REPO_URL}" \
  '. | .gpg_fingerprint=$gpg_fingerprint
     | .package_name=$package_name
     | .project_name=$project_name
     | .project_url=$project_url
     | .r2_bucket_name=$r2_bucket_name
     | .r2_bucket_url=$r2_bucket_url
     | .repo_arch_deb=$repo_arch_deb
     | .repo_arch_rpm=$repo_arch_rpm
     | .repo_name=$repo_name
     | .repo_url=$repo_url' \
  <<<'{}' )

echo "${JSON_DATA}" > "./liquid.json"
