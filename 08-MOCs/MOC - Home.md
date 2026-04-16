---
created: 2026-04-15
last_verified: 2026-04-15
confidence_level: high
decay_rate: slow
status: current
tags: [type/moc]
---

# 🏠 Home — Personal Knowledge Base

> Центральный навигационный хаб. Отсюда переходи в любой раздел базы знаний.

---

## ML / Computer Vision

### CV Задачи

- [[MOC - Object Detection]] — YOLO, DETR, Grounding DINO
- [[MOC - Image Segmentation]] — SAM, Mask2Former, SegFormer
- [[MOC - Image Classification]] — ViT, ConvNeXt, EfficientNet, CLIP
- [[MOC - Video Understanding]] — VideoMAE, ByteTrack, SAM2
- [[MOC - Multimodal VLM]] — LLaVA, InternVL, BLIP-2
- [[MOC - 3D Vision & Depth]] — Depth Anything, Gaussian Splatting

### Концепции

- [[MOC - Attention Mechanisms]] — Self-attention, Cross-attention, FlashAttention
- [[MOC - Training Techniques]] — Loss functions, augmentation, distillation
- [[MOC - Architectures]] — Transformer, SSM, CNN backbones

### Инструменты и пайплайны

- [[MOC - MLOps]] — трекинг экспериментов, деплой, мониторинг
- [[MOC - Data Engineering]] — датасеты, лейблинг, аугментация

### Навигация по типу

- [**Все модели**](../05-Models/) — карточки с бенчмарками
- [**Все бенчмарки**](../06-Benchmarks/) — датасеты и leaderboards
- [**Все статьи**](../02-Papers/) — заметки по статьям
- [**Проекты**](../01-Projects/) — активная работа

---

## Другие домены

> Домены добавляются командой `/add-domain <name>`. Ссылки появляются здесь автоматически.

*(пусто)*

---

## Dataview: Требуют ревизии

```dataview
TABLE last_verified, decay_rate, status
FROM ""
WHERE decay_rate = "fast" AND date(now) - date(last_verified) > dur(90 days)
SORT last_verified ASC
LIMIT 10
```

## Dataview: Низкая уверенность

```dataview
TABLE file.link, confidence_level, status
FROM ""
WHERE confidence_level = "low" OR confidence_level = "unverified"
SORT file.mtime DESC
LIMIT 10
```
