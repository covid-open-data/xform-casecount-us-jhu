#!/bin/bash
###############################################################################
# Docker container entrypoint script.
###############################################################################
ACTION_DIR="${GITHUB_WORKSPACE}/.github/actions/validate-csv"
source "${GITHUB_WORKSPACE}/.github/scripts/container.sh"

${ACTION_DIR}/exec.sh
exit $?
