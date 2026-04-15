@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  setup-mcps.bat  —  MCP Setup for ML/CV Obsidian Vault
REM  Запускай из папки vault двойным кликом или из терминала
REM ============================================================
REM  ПЕРЕД ЗАПУСКОМ:
REM  Замени YOUR_OBSIDIAN_API_KEY на ключ из плагина Local REST API
REM ============================================================

REM -- Vault = папка этого bat-файла (убираем trailing backslash)
set "VAULT=%~dp0"
if "!VAULT:~-1!"=="\" set "VAULT=!VAULT:~0,-1!"

REM -- Настройки mcp-obsidian
set "OBSIDIAN_API_KEY=YOUR_OBSIDIAN_API_KEY"
set "OBSIDIAN_HOST=http://localhost:27123"

echo.
echo === MCP Setup для ML/CV Vault ===
echo Vault: !VAULT!
echo.

REM ── 1. Установка QMD ──────────────────────────────────────
echo [1/3] Установка QMD (@tobilu/qmd)...
call npm install -g @tobilu/qmd
if %errorlevel%==0 (
    echo     OK: QMD установлен
) else (
    echo     WARN: npm не найден. Установи Node.js 18+ и повтори.
)

REM ── 2. Установка mcp-obsidian ─────────────────────────────
echo [2/3] Установка mcp-obsidian...
call pip install mcp-obsidian
if %errorlevel%==0 (
    echo     OK: mcp-obsidian установлен
) else (
    echo     WARN: pip не найден. Установи Python 3.11+ и повтори.
)

REM ── 3. Обновление claude_desktop_config.json через Python ─
echo [3/3] Обновление claude_desktop_config.json...

if not exist "%APPDATA%\Claude" mkdir "%APPDATA%\Claude"

REM Пишем Python-хелпер во временный файл
(
echo import json, os
echo config_path = os.path.join(os.environ['APPDATA'], 'Claude', 'claude_desktop_config.json')
echo vault       = r"!VAULT!"
echo api_key     = "!OBSIDIAN_API_KEY!"
echo obs_host    = "!OBSIDIAN_HOST!"
echo try:
echo     with open(config_path, encoding='utf-8'^) as f:
echo         cfg = json.load(f^)
echo except:
echo     cfg = {}
echo cfg.setdefault('mcpServers', {})
echo cfg['mcpServers']['qmd'] = {
echo     'command': 'npx',
echo     'args': ['@tobilu/qmd', '--vault', vault, '--port', '8181']
echo }
echo cfg['mcpServers']['obsidian'] = {
echo     'command': 'python',
echo     'args': ['-m', 'mcp_obsidian'],
echo     'env': {'OBSIDIAN_API_KEY': api_key, 'OBSIDIAN_HOST': obs_host}
echo }
echo with open(config_path, 'w', encoding='utf-8'^) as f:
echo     json.dump(cfg, f, indent=2, ensure_ascii=False^)
echo print('    OK: конфиг сохранён ->', config_path^)
) > "%TEMP%\setup_mcps_helper.py"

python "%TEMP%\setup_mcps_helper.py"
del "%TEMP%\setup_mcps_helper.py"

REM ─────────────────────────────────────────────────────────
echo.
echo === Готово! ===
echo.
echo Следующие шаги:
echo   1. Перезапусти Claude Desktop
echo   2. Для mcp-obsidian:
echo      - Открой Obsidian
echo      - Settings ^> Community plugins ^> Local REST API ^> включи
echo      - Скопируй API Key, вставь в OBSIDIAN_API_KEY вверху этого файла
echo      - Запусти скрипт ещё раз
echo   3. Перед каждым сеансом запускай start-qmd.bat
echo.
pause
