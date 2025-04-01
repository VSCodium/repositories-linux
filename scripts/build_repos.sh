#!/usr/bin/env bash

set -e

GH_HOST="${GH_HOST:-github.com}"
GH_REPOSITORIES="${GH_REPOSITORIES:-VSCodium/vscodium VSCodium/vscodium-insiders}"
REPO_NAME="${REPO_NAME:-vscodium}"

GOT_DEB=0
GOT_RPM=0

get_install_files() {
  GH_REPOSITORY="$1"

  GITHUB_RESPONSE=$( curl --silent --fail "https://api.${GH_HOST}/repos/${GH_REPOSITORY}/releases/latest" )
  TAG=$( echo "${GITHUB_RESPONSE}" | jq -c -r '.tag_name' )

  FILES="$( echo "${GITHUB_RESPONSE}" | jq -r '.assets[] | select(.name | endswith(".rpm")) | .name' )"
  if [[ -n "${FILES}" ]]; then
    GOT_RPM=1

    mkdir -p pkgs/rpm
    pushd pkgs/rpm > /dev/null

    for REMOTE_FILE in ${FILES}; do
      # LOCAL_FILE=$( echo "${REMOTE_FILE}" | sed 's/\<codium\>/vscodium/g' )
      # LOCAL_FILE="${REMOTE_FILE//codium/vscodium}"
      LOCAL_FILE="${REMOTE_FILE}"

      if [ ! -f "${LOCAL_FILE}" ]; then
        echo "Getting RPM: ${REMOTE_FILE}"

        curl --silent --fail -L "https://${GH_HOST}/${GH_REPOSITORY}/releases/download/${TAG}/${REMOTE_FILE}" -o "${LOCAL_FILE}"
      fi
    done

    popd > /dev/null
  fi

  FILES="$( echo "${GITHUB_RESPONSE}" | jq -r '.assets[] | select(.name | endswith(".deb")) | .name' )"
  if [[ -n "${FILES}" ]]; then
    GOT_DEB=1

    mkdir -p tmp
    pushd tmp > /dev/null

    for REMOTE_FILE in ${FILES}; do
      # LOCAL_FILE="${REMOTE_FILE//codium/vscodium}"
      LOCAL_FILE="${REMOTE_FILE}"

      if [ ! -f "${LOCAL_FILE}" ]; then
        echo "Getting DEB: ${REMOTE_FILE}"

        curl --silent --fail -L "https://${GH_HOST}/${GH_REPOSITORY}/releases/download/${TAG}/${REMOTE_FILE}" -o "${LOCAL_FILE}"
      fi
    done

    popd > /dev/null
  fi
}

for GH_REPOSITORY in ${GH_REPOSITORIES}; do
  get_install_files "${GH_REPOSITORY}"
done

GPG_TTY=""
export GPG_TTY

if (( "${GOT_RPM}" )); then
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

if (( "${GOT_DEB}" )); then
  echo "== Scanning DEB packages and creating the repository"

  mkdir -p pkgs/deb/conf
  cp config/deb/distributions pkgs/deb/conf/distributions
  touch pkgs/deb/conf/option

  reprepro --verbose --basedir pkgs/deb includedeb "${REPO_NAME}" tmp/*deb

  if [[ -n "${GPG_FINGERPRINT}" ]]; then
    echo "Signing"

    pushd pkgs/deb/dist/${REPO_NAME} > /dev/null

    gpg --detach-sign --armor --sign > Release.gpg < Release
    gpg --detach-sign --armor --sign --clearsign > InRelease < Release

    popd > /dev/null
  fi

  echo "DEB repository built"
fi
