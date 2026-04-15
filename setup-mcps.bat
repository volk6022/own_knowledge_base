@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  setup-mcps.bat  —  MCP Setup for ML/CV Obsidian Vault
REM  Run from the vault folder by double-click or terminal
REM ============================================================
REM  BEFORE RUNNING:
REM  Replace YOUR_OBSIDIAN_API_KEY with the key from Local REST API plugin
REM ============================================================

REM -- Vault = folder of this bat file (strip trailing backslash)
set "VAULT=%~dp0"
if "!VAULT:~-1!"=="\" set "VAULT=!VAULT:~0,-1!"

REM -- mcp-obsidian settings
set "OBSIDIAN_API_KEY=YOUR_OBSIDIAN_API_KEY"
set "OBSIDIAN_HOST=http://localhost:27123"

echo.
echo === MCP Setup for ML/CV Vault ===
echo Vault: !VAULT!
echo.

REM ── 1. Install QMD and index vault ────────────────────────
echo [1/3] Installing QMD (@tobilu/qmd)...
call npm install -g @tobilu/qmd
if %errorlevel%==0 (
    echo     OK: QMD installed
    echo     Indexing vault collection...
    call npx @tobilu/qmd collection add "!VAULT!"
    echo     OK: vault indexed
) else (
    echo     WARN: npm not found. Install Node.js 18+ and retry.
)

REM ── 2. Install mcp-obsidian ───────────────────────────────
echo [2/3] Installing mcp-obsidian...
call pip install mcp-obsidian
if %errorlevel%==0 (
    echo     OK: mcp-obsidian installed
) else (
    echo     WARN: pip not found. Install Python 3.11+ and retry.
)

REM ── 3. Update claude_desktop_config.json via Python ───────
echo [3/3] Updating claude_desktop_config.json...

if not exist "%APPDATA%\Claude" mkdir "%APPDATA%\Claude"

python -c "import json,os; p=os.path.join(os.environ['APPDATA'],'Claude','claude_desktop_config.json'); cfg=(json.load(open(p,encoding='utf-8')) if os.path.exists(p) else {}); cfg.setdefault('mcpServers',{}); cfg['mcpServers']['qmd']={'command':'npx','args':['@tobilu/qmd','mcp']}; cfg['mcpServers']['obsidian']={'command':'python','args':['-m','mcp_obsidian'],'env':{'OBSIDIAN_API_KEY':os.environ['OBSIDIAN_API_KEY'],'OBSIDIAN_HOST':os.environ['OBSIDIAN_HOST']}}; open(p,'w',encoding='utf-8').write(json.dumps(cfg,indent=2,ensure_ascii=False)); print('    OK: config saved ->',p)"

REM ──────────────────────────────────────────────────────────
echo.
echo === Done! ===
echo.
echo Next steps:
echo   1. Restart Claude Desktop
echo   2. For mcp-obsidian:
echo      - Open Obsidian
echo      - Settings ^> Community plugins ^> Local REST API ^> enable
echo      - Copy the API Key, paste it into OBSIDIAN_API_KEY at the top of this file
echo      - Run this script again
echo   3. Run start-qmd.bat before each Claude session
echo.
pause
