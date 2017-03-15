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

ruby misc/fpm_recipe.rb

PACKAGE_CLOUD_REPO="tsuru/stable"
if [[ ${TRAVIS_TAG} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc"
fi

SUPPORTED_UBUNTU_VERSIONS="precise trusty xenial yakkety"
SUPPORTED_DEBIAN_VERSIONS="jessie stretch buster"
SUPPORTED_REDHAT_VERSIONS="6 7"
SUPPORTED_FEDORA_VERSIONS=$(seq 14 25)

gem install package_cloud --no-ri --no-rdoc
if [ -f dist/${GORELEASE_PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb ]; then
  mv dist/${GORELEASE_PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb dist/${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
else
  echo "File dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb not found."
  exit 1
fi

for ubuntu_version in ${SUPPORTED_UBUNTU_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/ubuntu/${ubuntu_version} ${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
done

for debian_version in ${SUPPORTED_DEBIAN_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/debian/${debian_version} ${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
done

for redhat_version in ${SUPPORTED_REDHAT_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/el/${redhat_version} ${PACKAGE_NAME}-${TRAVIS_TAG/-/_}-1_.x86_64.rpm
done

for fedora_version in ${SUPPORTED_FEDORA_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/fedora/${fedora_version} ${PACKAGE_NAME}-${TRAVIS_TAG/-/_}-1_.x86_64.rpm
done
