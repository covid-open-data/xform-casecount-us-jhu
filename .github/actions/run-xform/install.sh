#!/bin/bash

# Install all dependencies for the transformer if not already installed.
if ! `apt -qq list r-base 2>/dev/null | grep -qE "(installed|upgradeable)"`; then
  echo "Installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  apt-get install -y software-properties-common
  apt-get install -y dirmngr --install-recommends
  apt-get install -y apt-transport-https

  echo "Installing R..."
  add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran36/' --no-tty
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
  apt-get update
  apt-get install -y r-base r-base-core r-base-dev r-recommended
  apt-get install -y r-cran-tidyverse

  R --version
  exit $?
fi

exit 0
