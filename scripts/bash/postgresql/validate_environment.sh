#!/bin/bash

set -e

echo "Checking Python"

python --version

echo "Checking PostgreSQL"

psql --version

echo "Checking Java"

java -version

echo "Environment validation successful"