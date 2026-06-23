#!/bin/bash

set -e

if command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL already installed"
    exit 0
fi

echo "PostgreSQL installation required"

exit 0