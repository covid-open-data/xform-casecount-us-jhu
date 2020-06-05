#!/bin/bash
###############################################################################
# Execution Script.
###############################################################################
cd "${GITHUB_WORKSPACE}/output"

git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_NAME}"

if $(git status . | grep -q "Changes not staged for commit"); then
  echo "Staging changes."
  git add .
fi

if $(git status . | grep -q "Changes to be committed"); then

  if [ -z "${SKIP_COMMIT}" ]; then
    echo "Committing changes."
    git commit -m "Auto commit: $(date)"
  else
    echo "Skipping git commit..."
  fi

fi

if [ -z "${SKIP_PUSH}" ]; then
  echo "Pushing changes."
  git push --force
else
  echo "Skipping git push..."
fi
PUSH_STATUS=$?

if [ ${PUSH_STATUS} -eq 0 ]; then
  echo "Success."
else
  echo "Fail."
fi

exit ${PUSH_STATUS}
