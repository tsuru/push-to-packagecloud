#!/bin/bash

set -eo pipefail

GITTAG=${GITHUB_REF#"refs/tags/"}
if [[ $GITTAG == "" ]]; then
  GITTAG=${TRAVIS_TAG}
fi

if [ ! -n "${GITTAG}" -o ! -n "${PACKAGECLOUD_TOKEN}" -o ! -n "${PACKAGE_NAME}" ]; then
  echo "GITTAG, PACKAGECLOUD_TOKEN and PACKAGE_NAME must be set"
  exit 1
fi

if [[ $SKIP_GORELEASER == "" ]]; then
  GO_FOR_RELEASE=$(echo $GO_FOR_RELEASE | sed -r 's/([0-9]+\.[0-9]+).*$/\1/')
  GOARCH=$(go version | awk '{print $4}' | awk -F '/' '{print $2}')
  GORELEASER_CONFIG=${GORELEASER_CONFIG:-goreleaser.yml}
  GORELEASE_VERSION="v0.112.2"
  echo "GOARCH=${GOARCH} GORELEASE_VERSION=${GORELEASE_VERSION} GORELEASER_CONFIG=${GORELEASER_CONFIG}"

  TAR_FILE="/tmp/goreleaser.tar.gz"
  DOWNLOAD_URL="https://github.com/goreleaser/goreleaser/releases/download"
  test -z "$TMPDIR" && TMPDIR="$(mktemp -d)"

  download() {
    rm -f "$TAR_FILE"
    curl -s -L -o "$TAR_FILE" \
      "$DOWNLOAD_URL/$GORELEASE_VERSION/goreleaser_$(uname -s)_$(uname -m).tar.gz"
  }

  clean() {
    test -f ./coverage.txt && rm ./coverage.txt
    true
  }

  clean
  download
  tar -xf "$TAR_FILE" -C "$TMPDIR"
  "${TMPDIR}/goreleaser" --config "$GORELEASER_CONFIG"
fi

gem install specific_install
gem specific_install -l https://github.com/morpheu/fpm -b pleaserun_extra_options

export PACKAGE_VERSION=${GITTAG}
export PACKAGE_DIR="./dist/${PACKAGE_NAME}_linux_amd64"

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  PACKAGE_DIR="./dist/tsuru_linux_amd64"
fi

sudo apt-get update && sudo apt-get install rpm -y
gem install package_cloud

ruby misc/fpm_recipe.rb

PACKAGE_CLOUD_REPO="tsuru/stable"
if [[ ${PACKAGE_VERSION} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc"
fi

SUPPORTED_UBUNTU_VERSIONS="trusty xenial zesty bionic focal"
SUPPORTED_REDHAT_VERSIONS="6 7"
SUPPORTED_FEDORA_VERSIONS="31 32 33"
SUPPORTED_DEBIAN_VERSIONS="jessie stretch buster bullseye"
SUPPORTED_MINT_VERSIONS="sarah serena sonya sylvia tara tessa tina tricia ulyana"

for ubuntu_version in ${SUPPORTED_UBUNTU_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/ubuntu/${ubuntu_version} *.deb
done

for debian_version in ${SUPPORTED_DEBIAN_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/debian/${debian_version} *.deb
done

for redhat_version in ${SUPPORTED_REDHAT_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/el/${redhat_version} *.rpm
done

for fedora_version in ${SUPPORTED_FEDORA_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/fedora/${fedora_version} *.rpm
done

for mint_version in ${SUPPORTED_MINT_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/linuxmint/${mint_version} *.deb
done
