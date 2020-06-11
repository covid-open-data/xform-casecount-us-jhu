#!/bin/bash
###############################################################################
# Install base container dependencies.
###############################################################################
source "${GITHUB_WORKSPACE}/.github/scripts/shutils.sh"
installAptPackages apt-utils software-properties-common dirmngr apt-transport-https curl
add-apt-repository ppa:deadsnakes/ppa
apt-get update
installAptPackages python3.7 python3-pip wget jq
ln -s /usr/bin/python3.7 /usr/bin/python
ln -s /usr/bin/pip3 /usr/bin/pip
#TODO: Change this to prod pypi once it's published.
installPipPackage --index-url https://test.pypi.org/simple --extra-index-url https://pypi.org/simple csv-schema
installPipPackage yq
python --version
pip --version
csv-schema --version
exit $?
