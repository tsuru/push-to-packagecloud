#!/bin/bash

if [ ! -n "${TRAVIS_TAG}" -o ! -n "${PACKAGECLOUD_TOKEN}" -o ! -n "${PACKAGE_NAME}" ]; then
  echo "TRAVIS_TAG, PACKAGECLOUD_TOKEN and PACKAGE_NAME must be set"
  exit 1
fi

PACKAGE_CLOUD_REPO="tsuru/stable" 
if [[ ${TRAVIS_TAG} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc" 
fi

gem install package_cloud --no-ri --no-rdoc
if [ -f dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb ]; then
  mv dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb dist/${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb
  echo "package_cloud push ${PACKAGE_CLOUD_REPO} dist/${PACKAGE_NAME}_${TRAVIS_TAG}_amd64.deb"
else
  echo "File dist/${PACKAGE_NAME}_${TRAVIS_TAG}_linux_amd64.deb not found."
  exit 1
fi
