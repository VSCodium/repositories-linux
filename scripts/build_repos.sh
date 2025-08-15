#!/usr/bin/env bash

set -e

. ./scripts/utils.sh

GH_HOST="${GH_HOST:-github.com}"
GH_REPOSITORIES="${GH_REPOSITORIES:-VSCodium/vscodium VSCodium/vscodium-insiders}"
REPO_ARCH_DEB="${REPO_ARCH_DEB:-amd64 arm64 armhf}"
REPO_ARCH_RPM="${REPO_ARCH_RPM:-x86_64 aarch64 armv7hl}"
REPO_NAME="${REPO_NAME:-vscodium}"

GOT_DEB="no"
GOT_RPM="no"

get_install_files() {
  GH_REPOSITORY="$1"

  RELEASES=($( curl --silent --fail "https://api.${GH_HOST}/repos/${GH_REPOSITORY}/releases?per_page=10" | tr -d '[:space:]' | jq -c '.[]' ))

  declare -A RPM_MAP

  for ARCH in ${REPO_ARCH_RPM}; do
    for RELEASE in "${RELEASES[@]}"; do
      if [[ "${RPM_MAP["${ARCH}"]}" != "yes" ]]; then
        FILE="$( echo "${RELEASE}" | jq -r '.assets[] | select(.name | endswith(".rpm")) | select(.name | contains("'"${ARCH}"'")) | .name' )"
        if [[ -n "${FILE}" ]]; then
          GOT_RPM="yes"

          mkdir -p pkgs/rpm
          pushd pkgs/rpm > /dev/null

          if [[ ! -f "${FILE}" ]]; then
            echo "Getting RPM: ${FILE}"

            TAG=$( echo "${RELEASE}" | jq -c -r '.tag_name' )

            curl --silent --fail -L "https://${GH_HOST}/${GH_REPOSITORY}/releases/download/${TAG}/${FILE}" --output "${FILE}"
          fi

          popd > /dev/null

          RPM_MAP["${ARCH}"]="yes"
        fi
      fi
    done
  done

  declare -A DEB_MAP

  for ARCH in ${REPO_ARCH_DEB}; do
    for RELEASE in "${RELEASES[@]}"; do
      if [[ "${DEB_MAP["${ARCH}"]}" != "yes" ]]; then
        FILE="$( echo "${RELEASE}" | jq -r '.assets[] | select(.name | endswith(".deb")) | select(.name | contains("'"${ARCH}"'")) | .name' )"
        if [[ -n "${FILE}" ]]; then
          GOT_DEB="yes"

          mkdir -p tmp
          pushd tmp > /dev/null

          if [[ ! -f "${FILE}" ]]; then
            echo "Getting DEB: ${FILE}"

            TAG=$( echo "${RELEASE}" | jq -c -r '.tag_name' )

            curl --silent --fail -L "https://${GH_HOST}/${GH_REPOSITORY}/releases/download/${TAG}/${FILE}" --output "${FILE}"
          fi

          popd > /dev/null

          DEB_MAP["${ARCH}"]="yes"
        fi
      fi
    done
  done
}

for GH_REPOSITORY in ${GH_REPOSITORIES}; do
  get_install_files "${GH_REPOSITORY}"
done

GPG_TTY=""
export GPG_TTY

if [[ "${GOT_RPM}" == "yes" ]]; then
  echo "== Scanning RPM packages and creating the repository"

  pushd pkgs/rpm > /dev/null

  if [[ -n "${GPG_FINGERPRINT}" ]]; then
    echo "Signing"

    rpm --define "%_signature gpg" --define "%_gpg_name ${GPG_FINGERPRINT}" --addsign *rpm
  fi

  createrepo_c --database --compatibility .

  if [[ -n "${GPG_FINGERPRINT}" ]]; then
    echo "Signing the repo Metadata"

    gpg --detach-sign --armor repodata/repomd.xml
  fi

  popd > /dev/null

  echo "RPM repository built"
fi

if [[ "${GOT_DEB}" == "yes" ]]; then
  echo "== Scanning DEB packages and creating the repository"

  liquify "distributions" "config/deb"

  mkdir -p pkgs/deb/conf
  cp config/deb/distributions pkgs/deb/conf/distributions
  touch pkgs/deb/conf/option

  reprepro --verbose --basedir pkgs/deb includedeb "${REPO_NAME}" tmp/*deb

  echo "DEB repository built"
fi
