#!/usr/bin/env bash

set -e

if [[ "${CI}" != "true" ]]; then
  . ./.env
fi

npm install -g liquidjs marked-it-cli wrangler

rm -rf _site _pages _components
