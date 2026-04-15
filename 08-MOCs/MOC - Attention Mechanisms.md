---
created: 2026-04-15
last_verified: 2026-04-15
confidence_level: high
decay_rate: slow
status: current
tags: [type/moc, approach/transformer]
---

# MOC — Attention Mechanisms

> Хаб по механизмам внимания в ML/CV. Кросс-доменный: NLP, CV, аудио.

---

## Концепты

### Основы
- [[Self-Attention]] — базовый механизм Q/K/V
- [[Multi-Head Attention]] — параллельные головы внимания
- [[Cross-Attention]] — внимание между двумя последовательностями
- [[Positional Encoding]] — как задаётся позиция

### Эффективный Attention
- [[FlashAttention]] — IO-aware алгоритм, быстрее в 2-4x
- [[FlashAttention-2]] — улучшенный параллелизм
- [[Linear Attention]] — O(n) вместо O(n²)
- [[Sliding Window Attention]] — локальное окно (Longformer, Mistral)

### Вариации для CV
- [[Window Attention]] — Swin Transformer, локальные окна
- [[Deformable Attention]] — выборочные точки, DETR
- [[Cross-Scale Attention]] — FPN-aware attention

---

## Модели, использующие эти концепты
- [[ViT]] → Self-Attention для патчей изображения
- [[Swin Transformer]] → Window Attention + Shifted Windows
- [[DETR]] → Cross-Attention для детекции
- [[SAM 2]] → Cross-Attention промпт → изображение

---

## Статьи
- [[Vaswani2017-Attention Is All You Need]] — оригинальный трансформер
- [[Dosovitskiy2021-ViT]] — Vision Transformer
- [[Liu2021-Swin]] — Swin Transformer

---

## Related MOCs
- [[MOC - Architectures]]
- [[MOC - Object Detection]]
