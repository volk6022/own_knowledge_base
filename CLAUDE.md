# CLAUDE.md — Personal Knowledge Base Vault

Это персональный мульти-доменный vault Ивана. Ты — LLM-агент, работающий напрямую с Markdown-файлами этого vault.

## Структура папок

### Ядро (общее для всех доменов)

| Папка               | Назначение                                                                    |
| ------------------- | ----------------------------------------------------------------------------- |
| `00-Inbox/`         | Необработанный захват: быстрые заметки, клипы, идеи                           |
| `08-MOCs/`          | Навигационные хабы (Maps of Content) — кросс-доменные                         |
| `09-Archive/`       | Завершённые проекты и устаревший контент                                      |
| `_Templates/`       | Базовые шаблоны Templater (Concept, Paper, Model Card, Benchmark)             |
| `raw/`              | **Karpathy pattern**: исходные документы (flat + `raw/<domain_id>/`)          |
| `wiki/`             | **Karpathy pattern**: скомпилированная LLM-база (flat + `wiki/<domain_id>/`)  |
| `schema/`           | **Karpathy pattern**: инструкции для LLM, правила, промпты                    |

### Домен ML/CV (папки 01-07)

| Папка               | Назначение                                                                    |
| ------------------- | ----------------------------------------------------------------------------- |
| `01-Projects/`      | Активные ML-проекты с дедлайнами и экспериментами                             |
| `02-Papers/`        | Заметки по статьям (arXiv, Semantic Scholar, синхронизация с Zotero)          |
| `03-Concepts/`      | Атомарные концепт-заметки (Attention, BatchNorm, FPN, ViT...)                 |
| `04-Tasks/`         | CV-задачи как MOC (Object Detection, Segmentation, Depth Estimation...)       |
| `05-Models/`        | Карточки моделей с бенчмарками и frontmatter-метаданными                      |
| `06-Benchmarks/`    | Датасеты, leaderboards, SOTA-результаты                                       |
| `07-Code-Snippets/` | Переиспользуемые паттерны кода Python/PyTorch                                 |

## Домены

Vault поддерживает несколько доменов знаний. Папки 00-09 — домен ML/CV. Дополнительные домены создаются командой `/add-domain` и получают номера 10+.

### Реестр доменов

| Префикс | Домен | domain_id | Описание                         |
| ------- | ----- | --------- | -------------------------------- |
| 00-09   | ML/CV | ml        | Machine Learning, Computer Vision |

### Структура домена

Каждый домен (10+) — отдельная папка с минимальной начальной структурой:

```
NN-DomainName/
├── Concepts/                    # атомарные концепт-заметки домена
├── Resources/                   # ресурсы домена (аналог Models для ML)
├── _templates/                  # доменные шаблоны (Concept, Resource)
├── MOC - DomainName.md          # входной MOC домена
└── _domain.yaml                 # метаданные домена (domain_id, tag_axes)
```

Дополнительные подпапки (Papers/, Projects/, Benchmarks/, Code-Snippets/, Tasks/, Archive/) добавляются по мере необходимости.

### `_domain.yaml`

Файл метаданных домена:

```yaml
domain_id: <kebab-case>
domain_name: <Display Name>
created: YYYY-MM-DD
prefix: "NN"
tag_namespace: <domain_id>
description: "Краткое описание домена"
tag_axes:
  axis1: [value1, value2]
  axis2: [value1, value2]
resource_type: "Тип ресурсов в этом домене"
```

## Naming Conventions

- Папки ядра: `NN-Name/` (с цифровым префиксом 00-09)
- Папки доменов: `NN-DomainName/` (с префиксом 10+)
- Концепты: `kebab-case.md` (напр. `attention-mechanism.md`)
- Статьи: `AuthorYear-ShortTitle.md` (напр. `He2016-ResNet.md`)
- Модели/Ресурсы: `ModelName-Version.md` (напр. `YOLOv8-L.md`)
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
domain: ml                    # опционально: domain_id (ml, crypto, ...)
tags: [task/detection, approach/transformer, model/yolov8]
---
```

Для заметок моделей (ML) добавлять:
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

### ML/CV домен (теги без префикса — обратная совместимость)

- Тип задачи: `#task/detection`, `#task/segmentation`, `#task/classification`, `#task/depth`, `#task/vqa`
- Подход: `#approach/transformer`, `#approach/diffusion`, `#approach/cnn`, `#approach/ssm`
- Модель: `#model/yolov8`, `#model/sam`, `#model/clip`, `#model/detr`
- Метрика: `#metric/map`, `#metric/iou`, `#metric/fps`, `#metric/flops`

### Общие теги (все домены)

- Тип заметки: `#type/paper`, `#type/concept`, `#type/model-card`, `#type/moc`, `#type/resource`

### Теги других доменов (с namespace-префиксом)

Формат: `#<domain_id>/<axis>/<value>` — оси и значения определяются в `_domain.yaml` каждого домена.

Пример для домена `crypto`:
- `#crypto/topic/defi`, `#crypto/protocol/ethereum`, `#crypto/metric/tvl`

## Правила для LLM-агента (тебя)

1. **raw/ → wiki/** — ты редко пишешь в `raw/`, но активно пишешь в `wiki/`. Человек кладёт материал в `raw/` (или `raw/<domain_id>/`), ты компилируешь его в `wiki/` (или `wiki/<domain_id>/`).
2. **Wikilinks везде** — используй `[[название заметки]]` для связей; создавай заметки-заглушки для ещё несуществующих концептов.
3. **Frontmatter обязателен** — при создании любой заметки заполни frontmatter согласно схеме выше.
4. **Не изобретай факты** — если не уверен, ставь `confidence_level: low` и добавляй `[NEEDS VERIFICATION]`.
5. **MOC как навигация** — ссылки в MOC-файлах сопровождай кратким комментарием (одна строка).
6. **decay_rate** — быстроустаревающие: бенчмарки, SOTA, API (fast); концепты — medium/slow.
7. **Домены** — при работе с доменом 10+ читай `_domain.yaml` для тегов и структуры; используй доменные шаблоны из `NN-Domain/_templates/`.

## Доступные команды (skills)

- `/wiki <тема>` — создать или обновить wiki-статью по теме
- `/save <url или тема>` — сохранить источник из raw/ в wiki/
- `/autoresearch <вопрос>` — провести автоисследование и добавить в wiki/
- `/kb-lint` — health check vault: orphans, broken links, staleness, contradictions
- `/add-domain <name>` — создать новый домен знаний (папка 10+, шаблоны, MOC, метаданные)

## MCP-серверы

- **QMD** — семантический поиск по vault (BM25 + vector + LLM rerank)
- **mcp-obsidian** — REST API к Obsidian (требует запущенный Obsidian + Local REST API plugin)
