#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/postgresql.conf"

# Config read karo
DB_NAME=$(grep "^POSTGRESQL_DATABASE=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '[:space:]')

# Auto-detect running PostgreSQL port
DETECTED_PORT=$(sudo -u postgres psql -c "SHOW port;" 2>/dev/null | grep -E "^\s*[0-9]+" | tr -d ' ' || echo "5432")

echo "Detected PostgreSQL port : $DETECTED_PORT"
echo "Target database          : $DB_NAME"

# Database exists check
if sudo -u postgres psql -p $DETECTED_PORT -lqt 2>/dev/null | cut -d\| -f1 | grep -qw "$DB_NAME"; then
    echo "Database already exists : $DB_NAME"
    exit 0
fi

echo "Creating database : $DB_NAME"
sudo -u postgres psql -p $DETECTED_PORT -c "CREATE DATABASE \"$DB_NAME\";"
echo "Database created successfully"