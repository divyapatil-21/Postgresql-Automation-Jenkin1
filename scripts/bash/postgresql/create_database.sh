#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)"

CONFIG_FILE="${PROJECT_ROOT}/config/postgresql.conf"

DB_NAME=$(grep "^POSTGRESQL_DATABASE=" "$CONFIG_FILE" | cut -d'=' -f2)

if psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"
then
    echo "Database already exists : $DB_NAME"
    exit 0
fi

echo "Creating database : $DB_NAME"

psql -U postgres -c "CREATE DATABASE \"$DB_NAME\";"

echo "Database created successfully"