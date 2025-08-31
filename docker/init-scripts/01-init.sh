#!/bin/bash
set -e

# Create additional databases or users if needed
# psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
#     CREATE USER app_user WITH PASSWORD 'app_password';
#     CREATE DATABASE app_db OWNER app_user;
#     GRANT ALL PRIVILEGES ON DATABASE app_db TO app_user;
# EOSQL

echo "Database initialization completed"
