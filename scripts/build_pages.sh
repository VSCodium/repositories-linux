#!/usr/bin/env bash

set -e

. ./scripts/utils.sh

liquify "{{repo_name}}.list/index.html {{repo_name}}.sources/index.html {{repo_name}}.repo/index.html" "pages" "_site"

liquify "index.md" "pages" "_pages"
liquify "header.html" "pages" "_components"

npx marked-it-cli _pages --output=_site --header-file=_components/header.html --footer-file=pages/footer.html

cp -r assets/* _site

# find assets -type f -print0 | xargs -0 ls -ld
# find _site -type f -print0 | xargs -0 ls -ld
