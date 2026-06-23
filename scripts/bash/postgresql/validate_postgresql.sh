#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"
PG_PORT=5432

export PATH="$PG_BIN:$PATH"
export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"

echo "Validating PostgreSQL..."

# pg_ctl check
if ! "$PG_BIN/pg_ctl" -D "$PROJECT_ROOT/databases/postgresql/data" status > /dev/null 2>&1; then
    echo "FAILED: PostgreSQL is not running"
    exit 1
fi

echo "PostgreSQL is running"

# psql version
"$PG_BIN/psql" -U postgres -p $PG_PORT -h localhost -c "SELECT version();"

# Database check
CONFIG_FILE="$PROJECT_ROOT/config/postgresql.conf"
DB_NAME=$(grep "^POSTGRESQL_DATABASE=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '[:space:]')

if "$PG_BIN/psql" -U postgres -p $PG_PORT -h localhost -lqt | cut -d\| -f1 | grep -qw "$DB_NAME"; then
    echo "Database exists: $DB_NAME"
else
    echo "FAILED: Database not found: $DB_NAME"
    exit 1
fi

echo "PostgreSQL validation successful"