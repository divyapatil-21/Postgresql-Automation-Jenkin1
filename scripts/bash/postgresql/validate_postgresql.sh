#!/bin/bash

set -e

if ! command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL not found"
    exit 1
fi

psql --version

echo "PostgreSQL validation successful"