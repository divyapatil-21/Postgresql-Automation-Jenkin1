#!/bin/bash

set -e

if systemctl is-active --quiet postgresql; then
    echo "PostgreSQL already running"
    exit 0
fi

sudo systemctl start postgresql

echo "PostgreSQL started successfully"