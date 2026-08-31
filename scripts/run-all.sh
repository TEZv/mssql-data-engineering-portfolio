#!/usr/bin/env bash
set -euo pipefail

container="${SQL_CONTAINER:-mssql-portfolio}"
password="${MSSQL_SA_PASSWORD:-Portfolio_SQL_2026_Strong!}"
sqlcmd=(docker exec -i "$container" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$password" -C -b -r1)

run_file() {
  local file="$1"
  echo "Running $file"
  "${sqlcmd[@]}" < "$file"
}

for project in projects/01-retail-erp-warehouse projects/02-media-performance-mart projects/03-sql-server-reliability; do
  while IFS= read -r file; do run_file "$file"; done < <(find "$project/sql" -maxdepth 1 -name '*.sql' | sort)
done

echo "All SQL projects and assertions completed."
