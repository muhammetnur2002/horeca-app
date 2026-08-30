# Пересоздаёт локальную базу и прогоняет миграции и проверки.
# Требуется PostgreSQL с psql в PATH.
#
#   .\run_local.ps1              полный прогон с проверками
#   .\run_local.ps1 -Seed        ещё и демо-данные

param(
    [string]$Database = "akyl_dev",
    [string]$DbUser   = "postgres",
    [string]$DbHost   = "localhost",
    [int]   $Port     = 5432,
    [switch]$Seed
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$env:PGUSER = $DbUser
$env:PGHOST = $DbHost
$env:PGPORT = $Port

function Run-Sql($file) {
    Write-Host "  -> $(Split-Path $file -Leaf)"
    & psql -q -d $Database -v ON_ERROR_STOP=1 -f $file
    if ($LASTEXITCODE -ne 0) { throw "Ошибка в $file" }
}

Write-Host "`nПересоздаю базу $Database" -ForegroundColor Cyan
& psql -d postgres -c "drop database if exists $Database" | Out-Null
& psql -d postgres -c "create database $Database"          | Out-Null

Write-Host "`nЗаглушка Supabase Auth" -ForegroundColor Cyan
Run-Sql (Join-Path $root "local" "00_auth_shim.sql")

Write-Host "`nМиграции" -ForegroundColor Cyan
Get-ChildItem (Join-Path $root "migrations") -Filter *.sql | Sort-Object Name | ForEach-Object {
    Run-Sql $_.FullName
}

if ($Seed) {
    Write-Host "`nДемо-данные" -ForegroundColor Cyan
    Run-Sql (Join-Path $root "local" "99_seed.sql")
}

Write-Host "`nПроверки доступа" -ForegroundColor Cyan
Get-ChildItem (Join-Path $root "tests") -Filter *.sql | Sort-Object Name | ForEach-Object {
    & psql -d $Database -v ON_ERROR_STOP=1 -f $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Проверки не пройдены: $($_.Name)" }
}

Write-Host "`nГотово.`n" -ForegroundColor Green
