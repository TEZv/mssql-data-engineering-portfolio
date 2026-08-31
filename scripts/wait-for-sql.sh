#!/usr/bin/env bash
set -euo pipefail

container="${SQL_CONTAINER:-mssql-portfolio}"
password="${MSSQL_SA_PASSWORD:-Portfolio_SQL_2026_Strong!}"

for attempt in $(seq 1 40); do
  if docker exec "$container" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$password" -C -Q "SELECT 1" >/dev/null 2>&1; then
    echo "SQL Server is ready."
    exit 0
  fi
  echo "Waiting for SQL Server ($attempt/40)..."
  sleep 3
done

echo "SQL Server did not become ready." >&2
exit 1
