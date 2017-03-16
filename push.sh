#!/bin/bash

TRAVIS_GO_VERSION=$(echo $TRAVIS_GO_VERSION | sed -r 's/([0-9]+\.[0-9]+).*$/\1/')
GO_FOR_RELEASE=$(echo $GO_FOR_RELEASE | sed -r 's/([0-9]+\.[0-9]+).*$/\1/')
if ! [ "${TRAVIS_GO_VERSION}" = "${GO_FOR_RELEASE}" -a "${TRAVIS_OS_NAME}" = "linux" ]; then
  echo "No package to build"
  exit 0
fi

if [ ! -n "${TRAVIS_TAG}" -o ! -n "${PACKAGECLOUD_TOKEN}" -o ! -n "${PACKAGE_NAME}" ]; then
  echo "TRAVIS_TAG, PACKAGECLOUD_TOKEN and PACKAGE_NAME must be set"
  exit 1
fi

gem install fpm --no-ri --no-rdoc && curl -sL https://git.io/goreleaser | bash

export PACKAGE_VERSION=${TRAVIS_TAG}
export PACKAGE_DIR="./dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64"

sudo apt-get install rpm -y
ruby misc/fpm_recipe.rb

PACKAGE_CLOUD_REPO="tsuru/stable"
if [[ ${TRAVIS_TAG} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc"
fi

SUPPORTED_UBUNTU_VERSIONS="precise trusty xenial yakkety"
SUPPORTED_REDHAT_VERSIONS="6 7"

gem install package_cloud --no-ri --no-rdoc

for ubuntu_version in ${SUPPORTED_UBUNTU_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/ubuntu/${ubuntu_version} *.deb
done

for redhat_version in ${SUPPORTED_REDHAT_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/el/${redhat_version} *.rpm
done
