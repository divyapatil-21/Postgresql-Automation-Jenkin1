#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)"

cd "${PROJECT_ROOT}/liquibase/postgresql"

"${PROJECT_ROOT}/tools/liquibase/liquibase" \
--defaultsFile=liquibase.properties \
update

echo "Liquibase execution successful"