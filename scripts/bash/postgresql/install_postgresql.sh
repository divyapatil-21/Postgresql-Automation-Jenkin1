#!/bin/bash
set -e

if command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL already installed: $(psql --version)"
    exit 0
fi

echo "PostgreSQL not found - installing automatically..."

sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-client

sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "PostgreSQL installed successfully: $(psql --version)"