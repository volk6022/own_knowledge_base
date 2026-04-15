# MCP Setup — Vault Integration

Инструкции по подключению MCP-серверов для работы с этим vault.

---

## 1. QMD — Семантический поиск

**Реальный пакет:** `@tobilu/qmd` (npm) — [GitHub](https://github.com/tobi/qmd)

**Что делает:** Гибридный поиск по vault (BM25 + vector + LLM rerank), всё локально через node-llama-cpp + GGUF. MCP endpoint: `http://localhost:8181/mcp`.

**Установка:**

```bash
# Глобальная установка
npm install -g @tobilu/qmd

# Запуск сервера (нужен перед использованием Claude)
npx @tobilu/qmd --vault "C:\path\to\local_knowlege_base" --port 8181
```

**В claude_desktop_config.json:**
```json
"qmd": {
  "command": "npx",
  "args": ["@tobilu/qmd", "--vault", "C:\\path\\to\\local_knowlege_base", "--port", "8181"]
}
```

> QMD запускается как HTTP-сервер. Claude подключается к нему через `http://localhost:8181/mcp`.

---

## 2. mcp-obsidian — REST API Bridge

**Что делает:** Позволяет читать/писать/искать заметки через Obsidian Local REST API. Нужен запущенный Obsidian.

**Шаг 1: Установить плагин Obsidian Local REST API**
1. Открыть Obsidian → Settings → Community plugins
2. Найти "Local REST API" (установить и включить)
3. Записать API key из настроек плагина

**Шаг 2: Установить mcp-obsidian**
```bash
# Python вариант (MarkusPfundstein)
pip install mcp-obsidian

# Добавить в Claude Code
claude mcp add-json obsidian '{
  "type": "stdio",
  "command": "python",
  "args": ["-m", "mcp_obsidian"],
  "env": {
    "OBSIDIAN_API_KEY": "YOUR_API_KEY_HERE",
    "OBSIDIAN_HOST": "http://localhost:27123"
  }
}'
```

**Доступные инструменты после подключения:**
- `list_files_in_vault` — список всех файлов
- `get_file_contents` — содержимое файла
- `search` — поиск по тексту
- `patch_content` — редактирование заметки
- `append_content` — добавление в заметку

---

## 3. Semantic Scholar MCP

**Что делает:** Поиск научных статей, цитирований, похожих работ (214M+ статей).

```bash
# Установка SemanticScholarMCP
npx -y @smithery/cli install SemanticScholarMCP --client claude

# Или вручную:
claude mcp add-json semantic-scholar '{
  "type": "stdio",
  "command": "npx",
  "args": ["semantic-scholar-mcp"]
}'
```

---

## 4. Firecrawl MCP — Web Scraping

**Что делает:** Конвертирует веб-страницы в чистый Markdown для добавления в raw/.

```bash
# Получи бесплатный API key на firecrawl.dev
claude mcp add-json firecrawl '{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "firecrawl-mcp"],
  "env": {
    "FIRECRAWL_API_KEY": "YOUR_KEY_HERE"
  }
}'
```

---

## Проверка всех MCP

```bash
claude mcp list
# Должно показать: qmd, obsidian (если Obsidian запущен), semantic-scholar, firecrawl
```

---

## Конфиг claude_desktop_config.json (альтернатива)

Если используешь Claude Desktop, добавь в `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "qmd": {
      "command": "npx",
      "args": ["qmd", "--vault", "/ABSOLUTE/PATH/TO/local_knowlege_base"]
    },
    "obsidian": {
      "command": "python",
      "args": ["-m", "mcp_obsidian"],
      "env": {
        "OBSIDIAN_API_KEY": "YOUR_KEY",
        "OBSIDIAN_HOST": "http://localhost:27123"
      }
    },
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "YOUR_KEY"
      }
    }
  }
}
```
