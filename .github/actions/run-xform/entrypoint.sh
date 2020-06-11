#!/bin/bash
###############################################################################
# Docker container entrypoint script.
###############################################################################
export ACTION_DIR="${GITHUB_WORKSPACE}/.github/actions/run-xform"
source "${GITHUB_WORKSPACE}/.github/scripts/shutils.sh"
export XFORM_COMMAND=$@

if [ -z "${XFORM_COMMAND}" ]; then
  echo "xform-command not provided, aborting."
  exit 1
fi

source "${GITHUB_WORKSPACE}/.github/scripts/container.sh"

echo "Executing: ${XFORM_COMMAND}"
eval ${XFORM_COMMAND}
ACTION_STATUS=$?

#TODO: remove after testing.
ACTION_STATUS=1

if [ ${ACTION_STATUS} -eq 0 ]; then
  echo "Success."
else
  createOnFailedGitHubIssue
  echo "Fail."
fi

exit ${ACTION_STATUS}
