#!/bin/sh
set -eu

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root}"
MYSQL_DATABASE="${MYSQL_DATABASE:-library}"
DB_DIR="${DB_DIR:-./db}"

run_mysql() {
  mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        --protocol=tcp --comments --show-warnings "$@"
}

echo "Waiting for MySQL at ${MYSQL_HOST}:${MYSQL_PORT}..."
until mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --protocol=tcp >/dev/null 2>&1; do
  sleep 1
done

echo "==> Running init.sql"
run_mysql < "${DB_DIR}/init.sql"

echo "==> Scanning ${DB_DIR} for SQL files..."
found_any=0
for f in "${DB_DIR}"/*.sql; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  [ "$base" = "init.sql" ] && continue

  if grep -Fq "?" "$f"; then
    echo ">>> skip (contains ?): $base"
    continue
  fi

  if grep -Ei -q '\b(CREATE|DROP)\s+(DATABASE|TABLE|PROCEDURE|FUNCTION|TRIGGER|EVENT)\b|\bALTER\s+TABLE\b|\bINSERT\s+INTO\b|\bUPDATE\b|\bDELETE\s+FROM\b|\bUSE\s+' "$f"; then
    echo ">>> run: $base"
    run_mysql -D "$MYSQL_DATABASE" < "$f"
    found_any=1
  else
    echo ">>> skip (no DDL/DML/routine): $base"
  fi
done
[ "$found_any" -eq 1 ] || echo ">>> (no extra SQL files ran)"

echo "==> Verifying stored procedures in '${MYSQL_DATABASE}'"
run_mysql -Nse "SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='${MYSQL_DATABASE}' AND ROUTINE_TYPE='PROCEDURE' ORDER BY ROUTINE_NAME;"

echo "==> SHOW CREATE for add_book_with_authors (if present)"
if ! run_mysql -e "SHOW CREATE PROCEDURE ${MYSQL_DATABASE}.add_book_with_authors\G"; then
  echo "(not found)"
fi

echo "All SQL applied."
