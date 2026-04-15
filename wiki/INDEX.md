---
created: 2026-04-15
last_verified: 2026-04-16
confidence_level: high
decay_rate: slow
status: current
tags: [type/index]
---

# Wiki Index

> Скомпилированная LLM-база знаний (паттерн Карпати). Этот файл — оглавление.
> Агент обновляет его при каждом добавлении новой wiki-статьи.

---

## CV Tasks

*(пусто — добавляй статьи через `/wiki <тема>`)*

## Concepts

- [[layer-fusion]] — слияние CUDA-kernels для ускорения inference; Conv+BN+ReLU → один kernel

## Models

*(пусто)*

## Benchmarks

*(пусто)*

## Tools & Methods

### Inference Optimization

- [[tensorrt]] — NVIDIA TensorRT: SDK для оптимизации DL моделей на GPU; 3–6× speedup vs PyTorch
- [[tensorrt-quantization]] — INT8/FP8/BF16 квантизация в TRT: PTQ, QAT, калибраторы, форматы точности
- [[tensorrt-deployment]] — деплоймент TRT в Triton Inference Server, DeepStream, TensorRT-LLM

---

> **Как наполнять:** Положи материал в `raw/` → попроси агента `/save <имя файла>` или `/wiki <тема>`
