#!/bin/sh

XFORM_COMMAND="${1}"

if [ -z "${GITHUB_WORKSPACE}" ]; then
  echo "GITHUB_WORKSPACE not set, aborting."
  exit 1
fi

if [ -z "${XFORM_COMMAND}" ]; then
  echo "xform-command not provided, aborting."
  exit 1
fi

cd "${GITHUB_WORKSPACE}"

.github/actions/run-xform/install.sh
INSTALL_STATUS=$?

if [ ${INSTALL_STATUS} -eq 0 ]; then
  echo "Executing: ${XFORM_COMMAND}"
  eval "${XFORM_COMMAND}"
  exit $?
else
  exit 1
fi