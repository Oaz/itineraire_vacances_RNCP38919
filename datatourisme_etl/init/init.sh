#!/bin/bash
set -e

until pg_isready; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready. Executing scripts."

echo "Executing create_database.sql..."
psql -U "$POSTGRES_USER" -f /docker-entrypoint-initdb.d/sql/000-database_create.sql

echo "Database initialization complete."