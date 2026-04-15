# ============================================================
# setup-mcps.ps1  —  MCP Setup for ML/CV Obsidian Vault
# ============================================================
# Что делает этот скрипт:
#   1. Устанавливает QMD (@tobilu/qmd) — локальный семантический поиск
#   2. Устанавливает mcp-obsidian — REST API bridge для Obsidian
#   3. Обновляет claude_desktop_config.json
#
# ПЕРЕД ЗАПУСКОМ:
#   - Укажи VAULT_PATH ниже (абсолютный путь к папке local_knowlege_base)
#   - Для mcp-obsidian: установи плагин "Local REST API" в Obsidian,
#     получи API Key и вставь его в OBSIDIAN_API_KEY
# ============================================================

# ┌─────────────────────────────────────────────────────────┐
# │  НАСТРОЙКИ — отредактируй эти значения                  │
# └─────────────────────────────────────────────────────────┘
$VAULT_PATH      = "C:\Users\bhunp\Documents\local_knowlege_base"   # <-- путь к vault
$OBSIDIAN_API_KEY = "YOUR_OBSIDIAN_API_KEY"                          # <-- ключ из плагина Local REST API
$OBSIDIAN_HOST   = "http://localhost:27123"                          # менять не нужно

# ─────────────────────────────────────────────────────────
$ConfigPath = "$env:APPDATA\Claude\claude_desktop_config.json"

Write-Host ""
Write-Host "=== MCP Setup для ML/CV Vault ===" -ForegroundColor Cyan
Write-Host ""

# ── 1. Установка QMD ──────────────────────────────────────
Write-Host "[1/3] Установка QMD (@tobilu/qmd)..." -ForegroundColor Yellow
try {
    npm install -g @tobilu/qmd
    Write-Host "    OK: QMD установлен" -ForegroundColor Green
} catch {
    Write-Host "    WARN: npm не найден. Установи Node.js 18+ и повтори." -ForegroundColor Red
}

# ── 2. Установка mcp-obsidian ─────────────────────────────
Write-Host "[2/3] Установка mcp-obsidian..." -ForegroundColor Yellow
try {
    pip install mcp-obsidian --break-system-packages 2>$null
    if ($LASTEXITCODE -ne 0) {
        pip install mcp-obsidian
    }
    Write-Host "    OK: mcp-obsidian установлен" -ForegroundColor Green
} catch {
    Write-Host "    WARN: pip не найден. Установи Python 3.11+ и повтори." -ForegroundColor Red
}

# ── 3. Обновление claude_desktop_config.json ──────────────
Write-Host "[3/3] Обновление $ConfigPath..." -ForegroundColor Yellow

# Создать папку если нет
$ConfigDir = Split-Path $ConfigPath
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

# Читаем существующий конфиг или создаём пустой
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{}
}

# Добавляем mcpServers если нет
if (-not ($config | Get-Member -Name "mcpServers" -MemberType NoteProperty)) {
    $config | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}

# QMD — запускается как HTTP-сервер, Claude подключается через SSE
$qmdServer = [PSCustomObject]@{
    command = "npx"
    args    = @("@tobilu/qmd", "--vault", $VAULT_PATH, "--port", "8181")
    env     = [PSCustomObject]@{}
}

# mcp-obsidian — stdio сервер, требует запущенного Obsidian с Local REST API
$obsidianServer = [PSCustomObject]@{
    command = "python"
    args    = @("-m", "mcp_obsidian")
    env     = [PSCustomObject]@{
        OBSIDIAN_API_KEY = $OBSIDIAN_API_KEY
        OBSIDIAN_HOST    = $OBSIDIAN_HOST
    }
}

# Добавляем серверы
$config.mcpServers | Add-Member -MemberType NoteProperty -Name "qmd"      -Value $qmdServer      -Force
$config.mcpServers | Add-Member -MemberType NoteProperty -Name "obsidian"  -Value $obsidianServer -Force

# Сохраняем
$config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "    OK: claude_desktop_config.json обновлён" -ForegroundColor Green

# ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Готово! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor White
Write-Host "  1. Перезапусти Claude Desktop" -ForegroundColor Gray
Write-Host "  2. Для mcp-obsidian:" -ForegroundColor Gray
Write-Host "     - Открой Obsidian" -ForegroundColor Gray
Write-Host "     - Settings → Community plugins → Local REST API → включи" -ForegroundColor Gray
Write-Host "     - Скопируй API Key из настроек плагина" -ForegroundColor Gray
Write-Host "     - Замени YOUR_OBSIDIAN_API_KEY в этом скрипте и запусти снова" -ForegroundColor Gray
Write-Host "  3. QMD запустится автоматически при старте Claude (через npx)" -ForegroundColor Gray
Write-Host ""
Write-Host "Конфиг: $ConfigPath" -ForegroundColor DarkGray
