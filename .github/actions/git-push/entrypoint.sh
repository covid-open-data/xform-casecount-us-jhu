#!/bin/bash
###############################################################################
# Docker container entrypoint script.
###############################################################################
ACTION_DIR="${GITHUB_WORKSPACE}/.github/actions/git-push"

if [ -z "${GIT_EMAIL}" ]; then
  echo "GIT_EMAIL not set, using SYSTEM@users.noreply.github.com."
  GIT_EMAIL="SYSTEM@users.noreply.github.com"
fi

if [ -z "${GIT_NAME}" ]; then
  echo "GIT_NAME not set, using SYSTEM."
  GIT_NAME="SYSTEM"
fi

source "${GITHUB_WORKSPACE}/.github/scripts/container.sh"

${ACTION_DIR}/exec.sh
exit $?
