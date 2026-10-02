# Сборка тестового APK (arm64) на Windows.
# Обходит две проблемы окружения:
#  1) кириллица в пути временной папки (C:\Users\<имя>\AppData\Local\Temp) —
#     Java/Gradle не может открыть loopback-сокет, поэтому TEMP переносим в C:\dev\tmp;
#  2) нестабильная загрузка SQLite с GitHub во время сборки — скачиваем файл
#     заранее с повторами и временно указываем сборке на локальную копию
#     (хеш файла всё равно проверяется пакетом sqlite3).
# Запуск из корня проекта:  powershell -ExecutionPolicy Bypass -File build_apk.ps1
$ErrorActionPreference = 'Stop'
$tmp = 'C:\dev\tmp'
$sqliteDir = Join-Path $tmp 'sqlite3'
New-Item -ItemType Directory -Force $sqliteDir | Out-Null
$env:TEMP = $tmp; $env:TMP = $tmp
$env:JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=$tmp -Djdk.net.unixdomain.tmpdir=$tmp"

$so = Join-Path $sqliteDir 'libsqlite3.arm64.android.so'
if (-not (Test-Path $so)) {
  $url = 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm64.android.so'
  curl.exe -sSL --retry 8 --retry-all-errors -m 300 -o $so $url
  if ($LASTEXITCODE -ne 0) { throw 'Не удалось скачать SQLite с GitHub — повторите позже.' }
}

$backup = Get-Content pubspec.yaml -Raw
try {
  Add-Content pubspec.yaml "`nhooks:`n  user_defines:`n    sqlite3:`n      source: test-sqlite3`n      directory: C:/dev/tmp/sqlite3/`n"
  flutter build apk --release --target-platform android-arm64
  if ($LASTEXITCODE -ne 0) { throw 'Сборка не удалась.' }
} finally {
  Set-Content pubspec.yaml $backup -NoNewline
}
$dst = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Akyl-test.apk'
Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' $dst -Force
Write-Host "Готово: $dst"
