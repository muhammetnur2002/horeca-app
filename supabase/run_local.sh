#!/usr/bin/env bash
# Пересоздаёт локальную базу и прогоняет миграции и проверки.
#   ./run_local.sh          полный прогон
#   ./run_local.sh --seed   ещё и демо-данные
set -euo pipefail

DB="${PGDATABASE:-akyl_dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo; echo "Пересоздаю базу $DB"
dropdb --if-exists "$DB"; createdb "$DB"

run() { echo "  -> $(basename "$1")"; psql -q -d "$DB" -v ON_ERROR_STOP=1 -f "$1"; }

echo; echo "Заглушка Supabase Auth"; run "$ROOT/local/00_auth_shim.sql"
echo; echo "Миграции"; for f in "$ROOT"/migrations/*.sql; do run "$f"; done
if [[ "${1:-}" == "--seed" ]]; then echo; echo "Демо-данные"; run "$ROOT/local/99_seed.sql"; fi
echo; echo "Проверки доступа"
for f in "$ROOT"/tests/*.sql; do psql -d "$DB" -v ON_ERROR_STOP=1 -f "$f"; done
echo; echo "Готово."; echo
