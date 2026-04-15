@echo off
REM ──────────────────────────────────────────────────────
REM  start-qmd.bat  —  Start QMD as HTTP MCP server
REM  Optional: Claude Desktop can launch QMD automatically
REM  via stdio (configured in setup-mcps.bat).
REM  Use this only if you want a persistent shared server.
REM ──────────────────────────────────────────────────────

echo [QMD] Starting HTTP MCP server...
echo [QMD] MCP endpoint: http://localhost:8181/mcp
echo [QMD] Press Ctrl+C to stop.
echo.

npx @tobilu/qmd mcp --http --port 8181
