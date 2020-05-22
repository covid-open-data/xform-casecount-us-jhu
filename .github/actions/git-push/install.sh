#!/bin/bash
###############################################################################
# Install dependencies.
###############################################################################

if ! $(apt -qq list git 2>/dev/null | grep -qE "(installed|upgradeable)"); then
  echo "Installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  apt-get install -y git

  git --version
  exit $?
fi

exit 0
