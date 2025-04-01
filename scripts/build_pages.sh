#!/usr/bin/env bash

set -e

. ./.env

npm install -g liquidjs marked-it-cli

rm -rf _site _pages _components

# generate context.json
JSON_DATA=$( jq \
  --arg package_name  "${PACKAGE_NAME}" \
  --arg project_name  "${PROJECT_NAME}" \
  --arg repo_arch     "${REPO_ARCH}" \
  --arg repo_name     "${REPO_NAME}" \
  --arg repo_url      "${REPO_URL}" \
  '. | .package_name=$package_name | .project_name=$project_name | .repo_arch=$repo_arch | .repo_name=$repo_name | .repo_url=$repo_url' \
  <<<'{}' )

echo "${JSON_DATA}" > "./liquid.json"

liquify() {
  FILES="$1"
  INPUT="$2"
  OUTPUT="${3:-"${INPUT}"}"
  echo "INPUT: ${INPUT}"
  echo "OUTPUT: ${OUTPUT}"

  for FILE in $FILES; do
    echo "FILE: ${FILE}"
    TARGET_FILE=$( npx liquidjs --template "${FILE}" --context @./liquid.json )
    echo "TARGET_FILE: ${TARGET_FILE}"
    TARGET_DIR=$( dirname "${TARGET_FILE}" )

    mkdir -p "${OUTPUT}/${TARGET_DIR}"

    npx liquidjs --template "@./${INPUT}/${FILE}.liquid" --context @./liquid.json > "./${OUTPUT}/${TARGET_FILE}"
  done
}

liquify "distributions" "config/deb"

liquify "{{repo_name}}.list/index.html {{repo_name}}.repo/index.html" "pages" "_site"

liquify "index.md" "pages" "_pages"
liquify "header.html" "pages" "_components"

npx marked-it-cli _pages --output=_site --header-file=_components/header.html --footer-file=pages/footer.html
