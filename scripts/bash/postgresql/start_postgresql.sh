#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_DIR="$PROJECT_ROOT/databases/postgresql"
PG_BIN="$PG_DIR/bin"
PG_DATA="$PG_DIR/data"
PG_LOG="$PROJECT_ROOT/outputs/logs/postgresql.log"
PG_PORT=5432

export PATH="$PG_BIN:$PATH"

# Already running check
if "$PG_BIN/pg_ctl" -D "$PG_DATA" status > /dev/null 2>&1; then
    echo "PostgreSQL already running from project folder"
    exit 0
fi

echo "Starting PostgreSQL from project folder..."
mkdir -p "$PROJECT_ROOT/outputs/logs"

"$PG_BIN/pg_ctl" -D "$PG_DATA" \
    -l "$PG_LOG" \
    -o "-p $PG_PORT" \
    start

sleep 3

"$PG_BIN/pg_ctl" -D "$PG_DATA" status
echo "PostgreSQL started successfully on port $PG_PORT"