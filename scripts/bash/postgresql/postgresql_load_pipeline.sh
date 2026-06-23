#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/load_data.sh"

bash "${SCRIPT_DIR}/validate_loaded_data.sh"