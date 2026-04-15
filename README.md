# ML/CV Knowledge Base

Персональный vault ML/CV-инженера на базе Obsidian + Claude. Архитектура: MOC + Zettelkasten + [Karpathy LLM Wiki](https://github.com/karpathy/llm.c/tree/master/dev/lm) pattern.

---

## Структура

```
local_knowlege_base/
├── 00-Inbox/          # быстрые заметки, клипы, необработанные идеи
├── 01-Projects/       # активные ML-проекты
├── 02-Papers/         # заметки по статьям (arXiv, Semantic Scholar)
├── 03-Concepts/       # атомарные концепты (Attention, BN, FPN, ViT...)
├── 04-Tasks/          # CV-задачи как MOC (Detection, Segmentation...)
├── 05-Models/         # карточки моделей с бенчмарками
├── 06-Benchmarks/     # датасеты, leaderboards, SOTA
├── 07-Code-Snippets/  # переиспользуемые паттерны PyTorch/Python
├── 08-MOCs/           # навигационные хабы (Maps of Content)
├── 09-Archive/        # завершённые проекты и устаревший контент
├── raw/               # исходники: PDF, репозитории, клипы (человек кладёт)
├── wiki/              # скомпилированная LLM-база (Claude пишет)
├── schema/            # инструкции для Claude: llm-instructions.md, mcp-setup.md
└── _Templates/        # шаблоны Templater для новых заметок
```

---

## Быстрый старт

### 1. Obsidian plugins (установить вручную)

Community plugins → включить:
- **Dataview** — запросы к заметкам как к базе данных
- **Templater** — шаблоны для новых заметок (`_Templates/`)
- **Obsidian Git** — автосинхронизация с git
- **Smart Connections** — AI-поиск прямо в Obsidian
- **Local REST API** — нужен для mcp-obsidian

### 2. MCP-серверы

Запусти `setup-mcps.bat` один раз (подробнее в `schema/mcp-setup.md`):

```bat
REM Установка QMD и mcp-obsidian + обновление claude_desktop_config.json
setup-mcps.bat
```

Перед каждым сеансом с Claude запускай QMD-сервер:

```bat
start-qmd.bat
```

### 3. Claude Skills (уже установлены)

| Скилл | Команда | Что делает |
|---|---|---|
| obsidian-wiki | `/wiki <тема>` | Создаёт/обновляет wiki-статью |
| obsidian-wiki | `/autoresearch <вопрос>` | Исследует тему и добавляет в wiki/ |
| obsidian-wiki | `/save <url>` | Сохраняет источник из raw/ в wiki/ |
| kb-lint | `/kb-lint` | Health check: orphans, broken links, staleness |

---

## Соглашения

**Именование файлов:** `kebab-case.md` для концептов, `AuthorYear-Title.md` для статей, `ModelName-Version.md` для моделей.

**Frontmatter** обязателен в каждой заметке — шаблоны в `_Templates/`.

**Теги:** `#task/detection`, `#approach/transformer`, `#model/yolo`, `#metric/map` и т.д.

**Правило raw→wiki:** Ты кладёшь материал в `raw/`, Claude компилирует в `wiki/`.

---

## Ссылки

- `08-MOCs/MOC - Home.md` — главный навигационный хаб
- `schema/llm-instructions.md` — инструкции для Claude-агента
- `schema/mcp-setup.md` — настройка MCP-серверов
