#!/usr/bin/env bash

set -e

if [[ "${CI}" != "true" ]]; then
  . ./.env
fi

npm install -g liquidjs marked-it-cli wrangler

rm -rf _site _pages _components

# generate context.json
JSON_DATA=$( jq \
  --arg package_name    "${PACKAGE_NAME}" \
  --arg project_name    "${PROJECT_NAME}" \
  --arg r2_bucket_name  "${R2_BUCKET_NAME}" \
  --arg repo_arch_deb   "${REPO_ARCH_DEB}" \
  --arg repo_name       "${REPO_NAME}" \
  --arg repo_url        "${REPO_URL}" \
  '. | .package_name=$package_name | .project_name=$project_name | .r2_bucket_name=$r2_bucket_name | .repo_arch_deb=$repo_arch_deb | .repo_name=$repo_name | .repo_url=$repo_url' \
  <<<'{}' )

echo "${JSON_DATA}" > "./liquid.json"

liquify() {
  FILES="$1"
  INPUT="$2"
  OUTPUT="${3:-"${INPUT}"}"

  for FILE in $FILES; do
    TARGET_FILE=$( npx liquidjs --template "${FILE}" --context @./liquid.json )
    TARGET_DIR=$( dirname "${TARGET_FILE}" )

    mkdir -p "${OUTPUT}/${TARGET_DIR}"

    npx liquidjs --template "@./${INPUT}/${FILE}.liquid" --context @./liquid.json > "./${OUTPUT}/${TARGET_FILE}"
  done
}

liquify "distributions" "config/deb"

liquify "{{repo_name}}.list/index.html {{repo_name}}.repo/index.html wrangler.toml" "pages" "_site"

liquify "index.md" "pages" "_pages"
liquify "header.html" "pages" "_components"

npx marked-it-cli _pages --output=_site --header-file=_components/header.html --footer-file=pages/footer.html

cp assets/* _site
