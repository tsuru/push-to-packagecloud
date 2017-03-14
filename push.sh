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

PACKAGE_CLOUD_REPO="tsuru/stable/ubuntu/trusty"
if [[ ${TRAVIS_TAG} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc/ubuntu/trusty"
fi

gem install package_cloud --no-ri --no-rdoc
if [ -f dist/${GORELEASE_PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb ]; then
  mv dist/${GORELEASE_PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb dist/${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
  package_cloud push ${PACKAGE_CLOUD_REPO} dist/${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
else
  echo "File dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb not found."
  exit 1
fi
