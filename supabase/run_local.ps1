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

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
$script:PsqlExe = if ($psqlCommand) { $psqlCommand.Source } else { $null }
if (-not $psqlCommand) {
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
function Format-PsqlArgument {
    <#
      Start-Process склеивает -ArgumentList пробелами и кавычек не ставит.
      Без экранирования аргумент "select 1" распадался на два, и psql
      принимал "1" за имя пользователя.
    #>
    param([string]$Value)
    if ($Value -match '\s') { return '"' + $Value.Replace('"', '\"') + '"' }
    return $Value
}

function Invoke-Psql {
    <#
      Запускает psql и печатает его вывод без искажений.

      Конвейер PowerShell здесь не годится: оболочка декодирует поток
      внешней программы кодовой страницей системы (для русской Windows —
      cp1251), а psql пишет в UTF-8. Кириллица превращалась в "Р—РђРњР•Р§РђРќРР•".
      Start-Process перенаправляет потоки средствами ОС, поэтому в файл
      попадают исходные байты, а Get-Content читает их явно как UTF-8.
    #>
    param([string[]]$Arguments)

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $quoted = $Arguments | ForEach-Object { Format-PsqlArgument $_ }
        $proc = Start-Process -FilePath $script:PsqlExe -ArgumentList $quoted `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        # Служебный префикс psql вида "psql:путь:строка: NOTICE:" только
        # мешает читать результаты проверок — снимаем его.
        $noise = '^psql:[^:]*:[0-9]+: (NOTICE|ЗАМЕЧАНИЕ):\s{0,2}'
        foreach ($file in @($outFile, $errFile)) {
            if ((Get-Item -LiteralPath $file).Length -gt 0) {
                Get-Content -LiteralPath $file -Encoding UTF8 |
                    ForEach-Object { Write-Host ($_ -replace $noise, '') }
            }
        }
        return $proc.ExitCode
    } finally {
        Remove-Item -LiteralPath $outFile, $errFile -ErrorAction SilentlyContinue
    }
}

function Test-DbConnection {
    # $ErrorActionPreference временно снимается неспроста. При перенаправлении
    # потока ошибок нативной программы PowerShell превращает её вывод
    # в объекты-ошибки, а режим Stop делает такую ошибку фатальной —
    # скрипт падал вместо того, чтобы переспросить пароль.
    # Start-Process требует разных файлов для потоков вывода и ошибок.
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $script:PsqlExe `
            -ArgumentList @("-w", "-d", "postgres", "-tAc", '"select 1"') `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        return ($proc.ExitCode -eq 0)
    } finally {
        Remove-Item -LiteralPath $outFile, $errFile -ErrorAction SilentlyContinue
    }
}

function Invoke-Sql {
    param([string]$Path)
    Write-Host ("  -> " + (Split-Path $Path -Leaf))
    $code = Invoke-Psql @("-w", "-q", "-d", $Database, "-v", "ON_ERROR_STOP=1", "-f", $Path)
    if ($code -ne 0) { throw "Ошибка в файле $Path" }
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
        throw ("Не удалось подключиться к PostgreSQL на $DbHost`:$Port под пользователем $DbUser.`n" +
               "  * Сервер запущен? Проверить: Test-NetConnection 127.0.0.1 -Port $Port -InformationLevel Quiet`n" +
               "    Запустить: & 'C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe' -D C:\pgdata start`n" +
               "  * Пароль забыт? В pg_hba.conf временно поставьте trust вместо scram-sha-256,`n" +
               "    перезапустите сервер и задайте новый: ALTER USER postgres PASSWORD '...'")
    }
    $env:PGPASSWORD = Read-DbPassword "Пароль пользователя $DbUser"
}

Write-Host "  подключение установлено" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Пересоздаю базу $Database" -ForegroundColor Cyan
$code = Invoke-Psql @("-w", "-d", "postgres", "-q", "-c", "drop database if exists $Database")
if ($code -ne 0) { throw "Не удалось удалить базу $Database" }
$code = Invoke-Psql @("-w", "-d", "postgres", "-q", "-c", "create database $Database")
if ($code -ne 0) { throw "Не удалось создать базу $Database" }

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
    $code = Invoke-Psql @("-w", "-q", "-d", $Database, "-v", "ON_ERROR_STOP=1", "-f", $t.FullName)
    if ($code -ne 0) { throw "Проверки не пройдены: $($t.Name)" }
}

Write-Host ""
Write-Host "Готово." -ForegroundColor Green
Write-Host ""
