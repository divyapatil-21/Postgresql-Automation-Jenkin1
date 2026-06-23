#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)"

python \
"${PROJECT_ROOT}/scripts/python/postgresql/validate_loaded_data.py"

echo "Loaded data validation successful"