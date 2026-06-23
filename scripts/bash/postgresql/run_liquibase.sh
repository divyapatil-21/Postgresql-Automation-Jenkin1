#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"
PG_PORT=5432

export PATH="$PG_BIN:$PATH"
export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"

CONFIG_FILE="$PROJECT_ROOT/config/postgresql.conf"
DB_NAME=$(grep "^POSTGRESQL_DATABASE=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '[:space:]')
DRIVER_VERSION=$(grep "^POSTGRESQL_DRIVER_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '[:space:]')
LIQUIBASE_VERSION=$(grep "^LIQUIBASE_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '[:space:]')

DRIVERS_DIR="$PROJECT_ROOT/tools/drivers"
LIQUIBASE_DIR="$PROJECT_ROOT/tools/liquibase"
DRIVER_JAR="$DRIVERS_DIR/postgresql-${DRIVER_VERSION}.jar"

echo "DB Name           : $DB_NAME"
echo "Driver Version    : $DRIVER_VERSION"
echo "Liquibase Version : $LIQUIBASE_VERSION"

# Download driver if missing
mkdir -p "$DRIVERS_DIR"
if [ ! -f "$DRIVER_JAR" ]; then
    echo "Downloading PostgreSQL JDBC driver..."
    wget -q "https://repo1.maven.org/maven2/org/postgresql/postgresql/${DRIVER_VERSION}/postgresql-${DRIVER_VERSION}.jar" \
        -O "$DRIVER_JAR"
    echo "Driver downloaded: $DRIVER_JAR"
else
    echo "Driver already exists: $DRIVER_JAR"
fi

# Download Liquibase if missing
mkdir -p "$LIQUIBASE_DIR"
if [ ! -f "$LIQUIBASE_DIR/liquibase" ]; then
    echo "Downloading Liquibase ${LIQUIBASE_VERSION}..."
    wget -q "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" \
        -O /tmp/liquibase.tar.gz
    tar -xzf /tmp/liquibase.tar.gz -C "$LIQUIBASE_DIR"
    chmod +x "$LIQUIBASE_DIR/liquibase"
    echo "Liquibase installed"
else
    echo "Liquibase already exists: $LIQUIBASE_DIR"
fi

# Run Liquibase
echo "Running Liquibase migrations..."

"$LIQUIBASE_DIR/liquibase" \
    --classpath="$DRIVER_JAR" \
    --driver=org.postgresql.Driver \
    --url="jdbc:postgresql://localhost:${PG_PORT}/${DB_NAME}" \
    --username=postgres \
    --searchPath="$PROJECT_ROOT,$PROJECT_ROOT/liquibase/postgresql" \
    --changeLogFile="liquibase/postgresql/master.xml" \
    update

echo "Liquibase migrations completed successfully"