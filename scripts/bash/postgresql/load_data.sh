#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"

export PATH="$PG_BIN:$PATH"
export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"

echo "Loading data into PostgreSQL..."

python3 "${PROJECT_ROOT}/scripts/python/postgresql/load_all.py"

echo "Data load successful"