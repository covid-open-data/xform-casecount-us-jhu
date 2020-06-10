#!/bin/bash
###############################################################################
# Docker container entrypoint script.
###############################################################################
export ACTION_DIR="${GITHUB_WORKSPACE}/.github/actions/run-xform"
export XFORM_COMMAND=$@

if [ -z "${XFORM_COMMAND}" ]; then
  echo "xform-command not provided, aborting."
  exit 1
fi

source "${GITHUB_WORKSPACE}/.github/scripts/container.sh"

echo "Executing: ${XFORM_COMMAND}"
eval ${XFORM_COMMAND}
XFORM_STATUS=$?

if [ ${XFORM_STATUS} -eq 0 ]; then
  echo "Success."
else
  echo "Fail."
fi

exit ${XFORM_STATUS}
