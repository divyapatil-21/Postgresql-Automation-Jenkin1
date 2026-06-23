#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"
PG_PORT=5432

CONFIG_FILE="$PROJECT_ROOT/config/postgresql.conf"
DB_NAME=$(grep "^POSTGRESQL_DATABASE=" "$CONFIG_FILE" | cut -d'=' -f2)

export PATH="$PG_BIN:$PATH"

echo "Checking database: $DB_NAME"

# Database exists check
if "$PG_BIN/psql" -U postgres -p $PG_PORT -lqt | cut -d\| -f1 | grep -qw "$DB_NAME"; then
    echo "Database already exists: $DB_NAME"
    exit 0
fi

echo "Creating database: $DB_NAME"
"$PG_BIN/psql" -U postgres -p $PG_PORT -c "CREATE DATABASE \"$DB_NAME\";"
echo "Database created successfully"