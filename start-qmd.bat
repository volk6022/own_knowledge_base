@echo off
REM ──────────────────────────────────────────────────────
REM  start-qmd.bat  —  Запуск QMD сервера для ML/CV vault
REM  Запускай этот файл перед открытием Claude Desktop
REM ──────────────────────────────────────────────────────

REM Укажи путь к своему vault:
set VAULT=C:\Users\bhunp\Documents\local_knowlege_base

echo [QMD] Запуск семантического поиска...
echo [QMD] Vault: %VAULT%
echo [QMD] MCP endpoint: http://localhost:8181/mcp
echo.
echo [QMD] Первый запуск скачает GGUF-модель (~500 MB) — подожди.
echo [QMD] Ctrl+C для остановки.
echo.

npx @tobilu/qmd --vault "%VAULT%" --port 8181
