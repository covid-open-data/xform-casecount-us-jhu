#!/bin/bash

SCHEMA_DIR=$(mktemp -d)
echo "Schema dir created: ${SCHEMA_DIR}"

validate_file() {
  FILE_PATH="$1"
  SCHEMA_URL="$2"

  echo "================================================================================"
  echo "File: ${FILE_PATH}"
  echo "Schema: ${SCHEMA_URL}"

  if [ ! -f "${FILE_PATH}" ]; then
    echo "File does not exist. Skipping."
    return
  fi

  SCHEMA_FILENAME=$(basename "${SCHEMA_URL}")
  SCHEMA_PATH="${SCHEMA_DIR}/${SCHEMA_FILENAME}"

  if [ ! -f "${SCHEMA_PATH}" ]; then
    echo "Downloading schema file..."
    if ! wget "${SCHEMA_URL}" -O "${SCHEMA_PATH}"; then
      echo "Failed to download schema file. Aborting."
      exit 1
    fi
  fi

  if ! csv-schema validate-csv "${FILE_PATH}" "$SCHEMA_PATH"; then
    echo "CSV validation failed. Aborting."
    exit 1
  else
    echo "CSV validation succeeded."
  fi
}

cd "${GITHUB_WORKSPACE}"
YML_FILE=xform.yml

yq -c -r '.outputs[] | .file + "|" + .schema' "${YML_FILE}" |
  while IFS='|' read -r file schema; do
    validate_file $file $schema
  done

exit 0
