#!/usr/bin/env bash

set -e

. ./scripts/utils.sh

liquify "{{repo_name}}.list/index.html {{repo_name}}.sources/index.html {{repo_name}}.repo/index.html" "pages" "_site"

liquify "index.html" "pages" "_site"

npx @tailwindcss/cli --input ./pages/main.css --output ./_site/main.css --minify

cp -r assets/* _site

# find assets -type f -print0 | xargs -0 ls -ld
# find _site -type f -print0 | xargs -0 ls -ld
