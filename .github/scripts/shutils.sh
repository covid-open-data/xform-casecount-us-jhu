export DEBIAN_FRONTEND=noninteractive

# Install packages via apt-get.
# Args: package names
# Example: installAptPackages git r-base other-pkg1 other-pkg2
installAptPackages() {
  for PACKAGE_NAME in "$@"; do
    if ! $(apt -qq list ${PACKAGE_NAME} 2>/dev/null | grep -qE "(installed|upgradeable)"); then
      # Ensure apt has been updated before any packages are installed.
      if [ -z "${APT_GET_UPDATED}" ]; then
        echo "Updating apt-get..."
        apt-get update
        export APT_GET_UPDATED=1
      fi

      echo "Installing package: ${PACKAGE_NAME}"

      apt-get install -y "${PACKAGE_NAME}"
      INSTALL_STATUS=$?

      if [ ${INSTALL_STATUS} -ne 0 ]; then
        echo "Package install failed. Aborting."
        exit 1
      fi
    fi
  done
}

# Install packages via pip.
# Args: pip args.
# Example: installPipPackage csv-schema
installPipPackage() {
  if ! pip install "$@"; then
    echo "Package install failed. Aborting."
    exit 1
  fi
}

# Execute a command and exit with status 1 if the command fails.
# Args: command to execute
# Example: execOrExit ls -al
execOrExit() {
  if ! "$@"; then
    exit 1
  fi
}

# Creates a GitHub action failure issue.
# Args: None.
createOnFailedGitHubIssue() {
  for REQUIRED_VAR in 'GITHUB_TOKEN' 'GITHUB_WORKFLOW' 'GITHUB_REPOSITORY'; do
    if [ -z "${!REQUIRED_VAR}" ]; then
      echo "WARNING: ${REQUIRED_VAR} environment variable not set. Cannot create GitHub issue."
      return 1
    fi
  done

  echo "Creating GitHub Issue for action: ${GITHUB_WORKFLOW}"
  curl --request POST \
    --url https://api.github.com/repos/${GITHUB_REPOSITORY}/issues \
    --header "authorization: Bearer ${GITHUB_TOKEN}" \
    --header 'content-type: application/json' \
    --data "{
          \"title\": \"GitHub Action FAILED: ${GITHUB_WORKFLOW}\",
          \"body\": \"This is an automated issue. See repo actions for details.\"
          }"
}
