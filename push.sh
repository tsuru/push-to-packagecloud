#!/bin/bash

TRAVIS_GO_VERSION=$(echo $TRAVIS_GO_VERSION | sed -r 's/([0-9]+\.[0-9]+).*$/\1/')
GO_FOR_RELEASE=$(echo $GO_FOR_RELEASE | sed -r 's/([0-9]+\.[0-9]+).*$/\1/')
GOARCH=$(go version | awk '{print $4}' | awk -F '/' '{print $2}')
echo "TRAVIS_GO_VERSION=${TRAVIS_GO_VERSION} GO_FOR_RELEASE=${GO_FOR_RELEASE} TRAVIS_OS_NAME=${TRAVIS_OS_NAME} GOARCH=${GOARCH}"
if ! [ "${TRAVIS_GO_VERSION}" = "${GO_FOR_RELEASE}" -a "${TRAVIS_OS_NAME}" = "linux" -a "${GOARCH}" = "amd64" ]; then
  echo "No package to build"
  exit 0
fi

if [ ! -n "${TRAVIS_TAG}" -o ! -n "${PACKAGECLOUD_TOKEN}" -o ! -n "${PACKAGE_NAME}" ]; then
  echo "TRAVIS_TAG, PACKAGECLOUD_TOKEN and PACKAGE_NAME must be set"
  exit 1
fi

TAR_FILE="/tmp/goreleaser.tar.gz"
DOWNLOAD_URL="https://github.com/morpheu/goreleaser/releases/download"
test -z "$TMPDIR" && TMPDIR="$(mktemp -d)"

last_version() {
  local header
  test -z "$GITHUB_TOKEN" || header="-H \"Authorization: token $GITHUB_TOKEN\""
  curl -s $header https://api.github.com/repos/morpheu/goreleaser/releases/latest |
    grep tag_name |
    cut -f4 -d'"'
}

download() {
  test -z "$VERSION" && VERSION="$(last_version)"
  test -z "$VERSION" && {
    echo "Unable to get goreleaser version." >&2
    exit 1
  }
  rm -f "$TAR_FILE"
  curl -s -L -o "$TAR_FILE" \
    "$DOWNLOAD_URL/$VERSION/goreleaser_$(uname -s)_$(uname -m).tar.gz"
}

download
tar -xf "$TAR_FILE" -C "$TMPDIR"
"${TMPDIR}/goreleaser"

gem install specific_install --no-ri --no-rdoc
gem specific_install -l https://github.com/morpheu/fpm -b pleaserun_extra_options

export PACKAGE_VERSION=${TRAVIS_TAG}
export PACKAGE_DIR="./dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64"

sudo apt-get install rpm -y
gem install package_cloud --no-ri --no-rdoc

ruby misc/fpm_recipe.rb

PACKAGE_CLOUD_REPO="tsuru/stable"
if [[ ${TRAVIS_TAG} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc"
fi

SUPPORTED_UBUNTU_VERSIONS="precise trusty xenial yakkety"
SUPPORTED_REDHAT_VERSIONS="6 7"
SUPPORTED_DEBIAN_VERSIONS="jessie"

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
