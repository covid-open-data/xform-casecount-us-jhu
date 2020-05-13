#!/bin/bash

# Install all dependencies for the transformer if not already installed.
if ! $(apt -qq list git 2>/dev/null | grep -qE "(installed|upgradeable)"); then
  echo "Installing dependencies..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  apt-get install -y git

  git --version
  exit $?
fi

exit 0
