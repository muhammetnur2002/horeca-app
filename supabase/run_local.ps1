# Пересоздаёт локальную базу, применяет миграции и прогоняет проверки.
#
#   .\run_local.ps1              полный прогон с проверками
#   .\run_local.ps1 -Seed        ещё и демо-данные
#
# Пароль можно задать заранее, иначе скрипт спросит его сам:
#   $env:PGPASSWORD = ...
#
# Либо передайте его параметром (удобно для автоматизации):
#   .\run_local.ps1 -Seed -Password ...
#
# КОДИРОВКА: файл сохранён в UTF-8 с BOM. Windows PowerShell 5.1 без BOM
# читает скрипт в кодировке системы, кириллица разваливается и ломает
# разбор строк. При правке сохраняйте кодировку.
#
# СОВМЕСТИМОСТЬ: рассчитан на Windows PowerShell 5.1. Не используйте здесь
# Join-Path с тремя аргументами, операторы ?: и ?? — это PowerShell 6+.

param(
    [string]$Database = "akyl_dev",
    [string]$DbUser   = "postgres",
    [string]$DbHost   = "127.0.0.1",
    [int]   $Port     = 5432,
    [string]$Password,
    [switch]$Seed
)

$ErrorActionPreference = "Stop"

# Консоль и psql должны говорить в UTF-8, иначе кириллица в выводе
# превратится в мусор на кодовой странице cp866.
# chcp обязателен: одной установки OutputEncoding мало. psql пишет вывод
# в UTF-8 (мы задали PGCLIENTENCODING), а консоль читает его в кодовой
# странице системы — сообщения сервера превращаются в "Р—РђРњР•Р§РђРќРР•".
try {
    if ($env:OS -eq "Windows_NT") { & chcp 65001 | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [Console]::OutputEncoding = $utf8NoBom
    $OutputEncoding = $utf8NoBom
} catch {
    Write-Host "Не удалось переключить консоль в UTF-8, вывод может искажаться." -ForegroundColor Yellow
}
$env:PGCLIENTENCODING = "UTF8"

$root = $PSScriptRoot
$dirLocal      = Join-Path $root "local"
$dirMigrations = Join-Path $root "migrations"
$dirTests      = Join-Path $root "tests"

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    throw "psql не найден в PATH. Добавьте каталог bin вашей установки PostgreSQL, например C:\Program Files\PostgreSQL\16\bin"
}

$env:PGUSER = $DbUser
$env:PGHOST = $DbHost
$env:PGPORT = $Port

function Read-DbPassword {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

# -w обязателен: без него psql при пустом PGPASSWORD сам выводит запрос
# пароля, перехватывает ввод и возвращает успех — а переменная остаётся
# пустой, и следующий же вызов psql падает с fe_sendauth.
function Test-DbConnection {
    & psql -w -d postgres -tAc "select 1" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Invoke-Sql {
    param([string]$Path)
    Write-Host ("  -> " + (Split-Path $Path -Leaf))
    & psql -w -q -d $Database -v ON_ERROR_STOP=1 -f $Path
    if ($LASTEXITCODE -ne 0) { throw "Ошибка в файле $Path" }
}

function Invoke-SqlDir {
    param([string]$Dir)
    $files = Get-ChildItem -Path $Dir -Filter *.sql | Sort-Object Name
    foreach ($f in $files) { Invoke-Sql $f.FullName }
}

Write-Host ""
Write-Host "Проверяю подключение" -ForegroundColor Cyan

if ($Password) { $env:PGPASSWORD = $Password }

# Пароль из окружения молча не принимаем: если он не подошёл, спрашиваем
# заново. Иначе оставшийся с прошлого раза PGPASSWORD блокирует запуск,
# а причина выглядит как отказ сервера.
if ($env:PGPASSWORD) {
    if (-not (Test-DbConnection)) {
        if (-not $Password) {
            Write-Host "Пароль из переменной PGPASSWORD не подошёл." -ForegroundColor Yellow
            $env:PGPASSWORD = $null
        }
    }
}

$attempt = 0
while (-not (Test-DbConnection)) {
    $attempt++
    if ($Password) {
        throw "Пароль, переданный параметром -Password, не подошёл для пользователя $DbUser."
    }
    if ($attempt -gt 3) {
        throw "Не удалось подключиться к PostgreSQL на $DbHost`:$Port под пользователем $DbUser. Проверьте, что служба PostgreSQL запущена (services.msc -> postgresql-x64-16). Если пароль забыт, его можно сбросить: в файле pg_hba.conf временно замените метод scram-sha-256 на trust, перезапустите службу и задайте новый пароль командой ALTER USER postgres PASSWORD '...'."
    }
    $env:PGPASSWORD = Read-DbPassword "Пароль пользователя $DbUser"
}

Write-Host "  подключение установлено" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Пересоздаю базу $Database" -ForegroundColor Cyan
& psql -w -d postgres -q -c "drop database if exists $Database"
if ($LASTEXITCODE -ne 0) { throw "Не удалось удалить базу $Database" }
& psql -w -d postgres -q -c "create database $Database"
if ($LASTEXITCODE -ne 0) { throw "Не удалось создать базу $Database" }

Write-Host ""
Write-Host "Заглушка Supabase Auth" -ForegroundColor Cyan
Invoke-Sql (Join-Path $dirLocal "00_auth_shim.sql")

Write-Host ""
Write-Host "Миграции" -ForegroundColor Cyan
Invoke-SqlDir $dirMigrations

if ($Seed) {
    Write-Host ""
    Write-Host "Демо-данные" -ForegroundColor Cyan
    Invoke-Sql (Join-Path $dirLocal "99_seed.sql")
}

Write-Host ""
Write-Host "Проверки доступа" -ForegroundColor Cyan
$testFiles = Get-ChildItem -Path $dirTests -Filter *.sql | Sort-Object Name
foreach ($t in $testFiles) {
    & psql -w -q -d $Database -v ON_ERROR_STOP=1 -f $t.FullName
    if ($LASTEXITCODE -ne 0) { throw "Проверки не пройдены: $($t.Name)" }
}

Write-Host ""
Write-Host "Готово." -ForegroundColor Green
Write-Host ""
