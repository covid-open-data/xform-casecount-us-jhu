#!/bin/bash
###############################################################################
# Install xform specific dependencies.
###############################################################################

# Space separated list of package names to install.
PACKAGES="r-cran-tidyverse"

for PACKAGE_NAME in ${PACKAGES}; do

  if ! $(apt -qq list ${PACKAGE_NAME} 2>/dev/null | grep -qE "(installed|upgradeable)"); then
    echo "Installing package: ${PACKAGE_NAME}"

    apt-get install -y "${PACKAGE_NAME}"
    INSTALL_STATUS=$?

    if [ ${INSTALL_STATUS} -ne 0 ]; then
      echo "Package install failed. Aborting."
      exit 1
    fi
  fi

done

exit 0
