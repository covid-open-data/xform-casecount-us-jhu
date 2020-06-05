#!/bin/bash
source "${GITHUB_WORKSPACE}/.github/scripts/shutils.sh"
###############################################################################
# Install xform specific dependencies.
###############################################################################

installAptPackages r-cran-tidyverse

exit 0
