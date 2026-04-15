# CLAUDE.md — ML/CV Knowledge Base Vault

Это персональный vault ML/CV-инженера Ивана. Ты — LLM-агент, работающий напрямую с Markdown-файлами этого vault.

## Структура папок

| Папка               | Назначение                                                                    |
| ------------------- | ----------------------------------------------------------------------------- |
| `00-Inbox/`         | Необработанный захват: быстрые заметки, клипы, идеи                           |
| `01-Projects/`      | Активные ML-проекты с дедлайнами и экспериментами                             |
| `02-Papers/`        | Заметки по статьям (arXiv, Semantic Scholar, синхронизация с Zotero)          |
| `03-Concepts/`      | Атомарные концепт-заметки (Attention, BatchNorm, FPN, ViT...)                 |
| `04-Tasks/`         | CV-задачи как MOC (Object Detection, Segmentation, Depth Estimation...)       |
| `05-Models/`        | Карточки моделей с бенчмарками и frontmatter-метаданными                      |
| `06-Benchmarks/`    | Датасеты, leaderboards, SOTA-результаты                                       |
| `07-Code-Snippets/` | Переиспользуемые паттерны кода Python/PyTorch                                 |
| `08-MOCs/`          | Навигационные хабы (Maps of Content)                                          |
| `09-Archive/`       | Завершённые проекты и устаревший контент                                      |
| `_Templates/`       | Шаблоны Templater для создания новых заметок                                  |
| `raw/`              | **Karpathy pattern**: исходные документы, PDF, репозитории (человек отбирает) |
| `wiki/`             | **Karpathy pattern**: скомпилированная LLM-база из .md-файлов (ты пишешь)     |
| `schema/`           | **Karpathy pattern**: инструкции для LLM, правила, промпты                    |

## Naming Conventions

- Папки: `NN-Name/` (с цифровым префиксом)
- Концепты: `kebab-case.md` (напр. `attention-mechanism.md`)
- Статьи: `AuthorYear-ShortTitle.md` (напр. `He2016-ResNet.md`)
- Модели: `ModelName-Version.md` (напр. `YOLOv8-L.md`)
- MOC-файлы: `MOC - Название.md`

## YAML Frontmatter

Каждая заметка должна содержать стандартный frontmatter:

```yaml
---
created: YYYY-MM-DD
source_date: YYYY-MM-DD       # дата публикации источника
last_verified: YYYY-MM-DD
confidence_level: high | medium | low | unverified
decay_rate: fast | medium | slow | static
status: current | needs-review | outdated | archived
tags: [task/detection, approach/transformer, model/yolov8]
---
```

Для заметок моделей добавлять:
```yaml
model_name: 
architecture:
task: [detection, segmentation, classification]
dataset:
benchmark_map: 
benchmark_fps:
sota_as_of: YYYY-MM-DD
```

## Таксономия тегов

- Тип задачи: `#task/detection`, `#task/segmentation`, `#task/classification`, `#task/depth`, `#task/vqa`
- Подход: `#approach/transformer`, `#approach/diffusion`, `#approach/cnn`, `#approach/ssm`
- Модель: `#model/yolov8`, `#model/sam`, `#model/clip`, `#model/detr`
- Метрика: `#metric/map`, `#metric/iou`, `#metric/fps`, `#metric/flops`
- Тип заметки: `#type/paper`, `#type/concept`, `#type/model-card`, `#type/moc`

## Правила для LLM-агента (тебя)

1. **raw/ → wiki/** — ты редко пишешь в `raw/`, но активно пишешь в `wiki/`. Человек кладёт материал в `raw/`, ты компилируешь его в `wiki/`.
2. **Wikilinks везде** — используй `[[название заметки]]` для связей; создавай заметки-заглушки для ещё несуществующих концептов.
3. **Frontmatter обязателен** — при создании любой заметки заполни frontmatter согласно схеме выше.
4. **Не изобретай факты** — если не уверен, ставь `confidence_level: low` и добавляй `[NEEDS VERIFICATION]`.
5. **MOC как навигация** — ссылки в MOC-файлах сопровождай кратким комментарием (одна строка).
6. **decay_rate** — быстроустаревающие: бенчмарки, SOTA, API (fast); концепты — medium/slow.

## Доступные команды (skills)

- `/wiki <тема>` — создать или обновить wiki-статью по теме
- `/save <url или тема>` — сохранить источник из raw/ в wiki/
- `/autoresearch <вопрос>` — провести автоисследование и добавить в wiki/
- `/kb-lint` — health check vault: orphans, broken links, staleness, contradictions

## MCP-серверы

- **QMD** — семантический поиск по vault (BM25 + vector + LLM rerank)
- **mcp-obsidian** — REST API к Obsidian (требует запущенный Obsidian + Local REST API plugin)
