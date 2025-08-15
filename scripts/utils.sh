#!/usr/bin/env bash

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
