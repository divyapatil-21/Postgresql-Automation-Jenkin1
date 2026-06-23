#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)"

DRIVER_DIR="${PROJECT_ROOT}/tools/drivers"

mkdir -p "${DRIVER_DIR}"

DRIVER_FILE="${DRIVER_DIR}/postgresql.jar"

if [ -f "${DRIVER_FILE}" ]; then
    echo "PostgreSQL JDBC Driver already exists"
    exit 0
fi

curl -L \
-o "${DRIVER_FILE}" \
https://jdbc.postgresql.org/download/postgresql-42.7.7.jar

echo "PostgreSQL JDBC Driver Downloaded Successfully"