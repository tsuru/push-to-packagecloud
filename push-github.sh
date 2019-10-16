#!/bin/bash -e

if [ ! -n "${PACKAGECLOUD_TOKEN}" -o ! -n "${PACKAGE_NAME}" ]; then
  echo "PACKAGECLOUD_TOKEN and PACKAGE_NAME must be set"
  exit 1
fi

gem install specific_install --no-ri --no-rdoc
gem specific_install -l https://github.com/morpheu/fpm -b pleaserun_extra_options

export PACKAGE_VERSION=${GITHUB_REF#"refs/tags/"}
export PACKAGE_DIR="./dist/${PACKAGE_NAME}_linux_amd64"

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  PACKAGE_DIR="./dist/tsuru_linux_amd64"
fi

sudo apt-get update && sudo apt-get install rpm -y
gem install package_cloud --no-ri --no-rdoc

ruby misc/fpm_recipe.rb

PACKAGE_CLOUD_REPO="tsuru/stable"
if [[ ${PACKAGE_VERSION} =~ .+-rc ]]; then
  PACKAGE_CLOUD_REPO="tsuru/rc"
fi

SUPPORTED_UBUNTU_VERSIONS="trusty xenial zesty bionic"
SUPPORTED_REDHAT_VERSIONS="6 7"
SUPPORTED_DEBIAN_VERSIONS="jessie stretch buster"
SUPPORTED_MINT_VERSIONS="sarah serena sonya sylvia tara tessa"

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

for mint_version in ${SUPPORTED_MINT_VERSIONS}
do
  package_cloud push ${PACKAGE_CLOUD_REPO}/linuxmint/${mint_version} *.deb
done
