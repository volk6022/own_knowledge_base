# Personal Knowledge Base

Персональный мульти-доменный vault на базе Obsidian + Claude. Архитектура: MOC + Zettelkasten + [Karpathy LLM Wiki](https://github.com/karpathy/llm.c/tree/master/dev/lm) pattern.

---

## Структура

```
own_knowledge_base/
├── 00-Inbox/          # быстрые заметки, клипы (общий)
├── 01-Projects/       # активные ML-проекты
├── 02-Papers/         # заметки по статьям (arXiv, Semantic Scholar)
├── 03-Concepts/       # атомарные ML-концепты (Attention, BN, FPN, ViT...)
├── 04-Tasks/          # CV-задачи как MOC (Detection, Segmentation...)
├── 05-Models/         # карточки моделей с бенчмарками
├── 06-Benchmarks/     # датасеты, leaderboards, SOTA
├── 07-Code-Snippets/  # переиспользуемые паттерны PyTorch/Python
├── 08-MOCs/           # навигационные хабы (Maps of Content) — кросс-доменные
├── 09-Archive/        # завершённые проекты (общий)
├── 10-DomainName/     # ← дополнительные домены создаются через /add-domain
│   ├── Concepts/
│   ├── Resources/
│   ├── _templates/
│   ├── MOC - DomainName.md
│   └── _domain.yaml
├── raw/               # исходники (flat + raw/<domain_id>/ подпапки)
├── wiki/              # скомпилированная LLM-база (flat + wiki/<domain_id>/)
├── schema/            # инструкции для Claude: llm-instructions.md, mcp-setup.md
└── _Templates/        # базовые шаблоны Templater
```

**Домены:** папки 00-09 — домен ML/CV. Новые домены (10+) создаются командой `/add-domain <name>` и получают минимальную структуру (Concepts/, Resources/, MOC, шаблоны). Подпапки добавляются по мере необходимости.

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
REM Устанавливает QMD и mcp-obsidian, индексирует vault, обновляет claude_desktop_config.json
setup-mcps.bat
```

После этого Claude Desktop запускает QMD автоматически (stdio). `start-qmd.bat` нужен только если хочешь держать QMD как постоянный HTTP-сервер.

### 3. Claude Skills (уже установлены)

| Скилл | Команда | Что делает |
|---|---|---|
| obsidian-wiki | `/wiki <тема>` | Создаёт/обновляет wiki-статью |
| obsidian-wiki | `/autoresearch <вопрос>` | Исследует тему и добавляет в wiki/ |
| obsidian-wiki | `/save <url>` | Сохраняет источник из raw/ в wiki/ |
| kb-lint | `/kb-lint` | Health check: orphans, broken links, staleness |
| add-domain | `/add-domain <name>` | Создаёт новый домен знаний (папка 10+, MOC, шаблоны) |

---

## Соглашения

**Именование файлов:** `kebab-case.md` для концептов, `AuthorYear-Title.md` для статей, `ModelName-Version.md` для моделей/ресурсов.

**Frontmatter** обязателен в каждой заметке — базовые шаблоны в `_Templates/`, доменные в `NN-Domain/_templates/`.

**Теги:** ML: `#task/detection`, `#approach/transformer`, `#model/yolo`. Другие домены: `#<domain_id>/<axis>/<value>`.

**Правило raw→wiki:** Кладёшь материал в `raw/` (или `raw/<domain_id>/`), Claude компилирует в `wiki/` (или `wiki/<domain_id>/`).

---

## Ссылки

- `08-MOCs/MOC - Home.md` — главный навигационный хаб
- `schema/llm-instructions.md` — инструкции для Claude-агента
- `schema/mcp-setup.md` — настройка MCP-серверов
