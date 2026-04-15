---
created: 2026-04-16
source_date: 2025-01-01
last_verified: 2026-04-16
confidence_level: high
decay_rate: fast
status: current
tags: [type/wiki, type/concept, approach/quantization, approach/inference-optimization]
aliases: [TRT, TensorRT SDK]
---

# TensorRT

> **NVIDIA TensorRT** — SDK для оптимизации обученных deep learning моделей под инференс на NVIDIA GPU. Решает задачу ускорения inference без переобучения модели: 3–6× прироста производительности по сравнению с нативным PyTorch.

## Зачем нужен TensorRT

Обученная PyTorch/TF модель — это граф вычислений, не оптимизированный под конкретное железо. TensorRT:

- **Сливает слои** (layer fusion): Conv + BN + ReLU → один CUDA-kernel
- **Выбирает лучший kernel** под конкретный GPU (auto-tuning tactics)
- **Снижает точность** (FP16/INT8/FP8/INT4) с минимальными потерями accuracy
- **Переиспользует память** активаций через анализ жизненного цикла тензоров
- **Удаляет мёртвые ветви** графа и сворачивает константы

Типичный результат: **3–5×** на FP16, **до 6×** на INT8 vs vanilla PyTorch inference.

---

## Архитектура — 4 стадии пайплайна

```
PyTorch / ONNX model
        │
        ▼
  [1] Parsing          ← nvonnxparser::IParser читает ONNX → INetworkDefinition
        │
        ▼
  [2] Optimization     ← Builder: layer fusion, precision calibration,
        │                 constant folding, dead-node removal
        ▼
  [3] Engine Building  ← Builder.build_engine_with_config() → ICudaEngine
        │                 (device-specific, hardware-locked plan)
        ▼
  [4] Runtime          ← Runtime.deserialize() → IExecutionContext → inference
```

### Ключевые объекты API

| Объект | Назначение |
|---|---|
| `tensorrt.Builder` | Строит ICudaEngine из INetworkDefinition |
| `INetworkDefinition` | DAG тензоров и слоёв (граф вычислений) |
| `IBuilderConfig` | Настройки билда: precision flags, workspace, profiling |
| `ICudaEngine` | Готовый оптимизированный движок (hardware-specific) |
| `IExecutionContext` | Контекст выполнения inference; один на поток |
| `IOptimizationProfile` | Min/opt/max shapes для динамических входов |

```python
# Минимальный пример: ONNX → TRT Engine
import tensorrt as trt

logger = trt.Logger(trt.Logger.WARNING)
builder = trt.Builder(logger)
network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
parser  = trt.OnnxParser(network, logger)

with open("model.onnx", "rb") as f:
    parser.parse(f.read())

config = builder.create_builder_config()
config.set_flag(trt.BuilderFlag.FP16)
config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 30)  # 1 GiB

engine = builder.build_serialized_network(network, config)
with open("model.trt", "wb") as f:
    f.write(engine)
```

---

## Ключевые оптимизации

### Layer Fusion
TensorRT сливает последовательные операции в один kernel, исключая промежуточные записи в VRAM.

Пример: `Conv → BatchNorm → ReLU` → **один fused kernel**

Подробнее: [[layer-fusion]]

### Kernel Auto-Tuning (Tactics)
Для каждого слоя TRT перебирает библиотеку CUDA-kernels и выбирает наиболее быстрый для конкретного GPU и input shape. Timing Cache позволяет переиспользовать результаты между сборками.

### Precision Calibration
Поддерживаемые форматы точности:

| Формат | Размер | Типичный speedup | Где |
|---|---|---|---|
| FP32 | 4B | 1× (baseline) | Всё |
| FP16 | 2B | 2–3× | Volta+ |
| BF16 | 2B | ~2× | Ampere+ |
| INT8 | 1B | 3–6× | Всё (требует калибровки) |
| FP8 | 1B | ~4× | Hopper+ (H100) |
| INT4 (WoQ) | 0.5B | 4–8× | LLM weights only |

Подробнее о квантизации: [[tensorrt-quantization]]

### Memory Optimization
- Динамическое переиспользование памяти активаций (live analysis)
- `CUDA_MODULE_LOADING=LAZY` снижает peak memory при <1% падении производительности
- `kWEIGHT_STREAMING` (TRT 10+): запуск модели, превышающей размер VRAM

### Dynamic Shapes
Переменные batch size / размеры входа задаются через `IOptimizationProfile`:

```python
profile = builder.create_optimization_profile()
profile.set_shape("input", min=(1,3,224,224), opt=(8,3,224,224), max=(32,3,224,224))
config.add_optimization_profile(profile)
```

Производительность максимальна при форме внутри диапазона `[min, max]` вблизи `opt`.

---

## Воркфлоу: PyTorch → TRT Engine

### Путь A: PyTorch → ONNX → TRT (наиболее универсальный)

```bash
# Шаг 1: экспорт в ONNX
python -c "
import torch, torchvision
model = torchvision.models.resnet50(pretrained=True).eval()
dummy = torch.randn(1, 3, 224, 224)
torch.onnx.export(model, dummy, 'resnet50.onnx', opset_version=17)
"

# Шаг 2: конвертация trtexec (CLI)
trtexec --onnx=resnet50.onnx \
        --saveEngine=resnet50_fp16.trt \
        --fp16 \
        --workspace=4096
```

### Путь B: torch.compile + TRT backend (наиболее простой)

```python
import torch
import torch_tensorrt

model = MyModel().eval().cuda()
compiled = torch.compile(model, backend="tensorrt")
# Первый вызов — компиляция; последующие — быстрый TRT inference
output = compiled(input_tensor)
```

Плюс: нет ручной работы с ONNX. Минус: меньше контроля над оптимизациями.

### Путь C: Torch-TensorRT (torch2trt)

```python
from torch2trt import torch2trt
model_trt = torch2trt(model, [example_input], fp16_mode=True)
```

### Инструменты

| Инструмент | Назначение |
|---|---|
| `trtexec` | CLI: ONNX → TRT, профилирование, бенчмарк |
| [[Polygraphy]] | Отладка, сравнение ONNX vs TRT outputs, FP16 анализ |
| [[Torch-TensorRT]] | PyTorch-нативная интеграция (torch.compile backend) |
| [[TensorRT Model Optimizer]] | Квантизация (INT8/INT4/FP8), pruning, distillation |

---

## Версии TensorRT

### TensorRT 10.x (актуальная, 2024–2025)
- **Weight Streaming** (`kWEIGHT_STREAMING`) — модели больше VRAM
- **IPluginV3** — новая plugin API с поддержкой data-dependent output shapes
- **Block Quantization** — INT4 WoQ с высокой гранулярностью масштабов
- **Fused Attention Operator** (`IAttention`) — встроенная multi-head attention
- **KVCacheUpdate API** — эффективный reuse KV-кэша в трансформерах
- **RoPE нативно** — `RotaryEmbedding` слой
- **Большие тензоры** (>2GB) в большинстве слоёв

### TensorRT 10.10+ (GB300 / DGX B300 / Blackwell)
- Поддержка NVIDIA GB300, DGX B300, DGX Spark
- Улучшенный BF16/FP16 GEMM для малых M/N/K (≤64)
- Расширенная MHA fusion для широких трансформерных паттернов

### Планируется TensorRT 11.0
- Новая интеграция с PyTorch/HuggingFace
- Modernized APIs, удаление legacy weakly-typed API

---

## Ограничения и gotchas

### Неподдерживаемые операции
- TRT не поддерживает все ops нативно; несовместимые части графа партиционируются и запускаются через PyTorch fallback
- **⚠️ Graph breaks** из-за fallback-операций могут съедать весь прирост
- Кастомные операции требуют реализации **Plugin** (`IPluginV3`)

### Аппаратная привязка
- Движки **hardware-specific**: нельзя перенести engine с A100 на V100 или на RTX 4090
- Пересборка обязательна при смене GPU

### Время компиляции
- Первый build крупных моделей (трансформеры, LLM) — **минуты или часы**
- Используй Timing Cache для ускорения повторных сборок

### Precision gotchas
- FP16: некоторые модели теряют accuracy → нужна per-layer precision настройка
- INT8: плохой калибрационный датасет → существенная деградация метрик
- Data-dependent shapes (NonMaxSuppression, NonZero): TRT 10.0–10.5 имел регрессию; fix в 10.6+

---

## Бенчмарки

| Сценарий | Speedup vs PyTorch |
|---|---|
| ResNet / CNN, FP16 | 2–4× |
| ViT / Transformer, FP16 | 2–3× |
| Diffusion model (FLUX.1-dev, FP8) | 2.4× |
| LLM inference (TRT-LLM) | до 4× throughput |
| LLM per-token latency | <10ms (H100) |
| INT8 общий | до 6× |

> ⚠️ `torch.compile` в 2024 показывает сопоставимые или лучшие результаты для ряда архитектур при значительно меньших усилиях интеграции. [NEEDS VERIFICATION для конкретных моделей]

---

## Деплоймент

Подробнее: [[tensorrt-deployment]]

- **Triton Inference Server** — multi-framework serving с dynamic batching; нативная поддержка TRT engines
- **DeepStream** — видеоаналитика; `Gst-nvinfer` (нативный TRT) / `Gst-nvinferserver` (Triton)
- **TensorRT-LLM** — специализированная библиотека для LLM inference на NVIDIA GPU

---

## Related Concepts

- [[layer-fusion]] — слияние слоёв, ключевая техника ускорения
- [[tensorrt-quantization]] — INT8/FP8/QAT/PTQ deep dive
- [[tensorrt-deployment]] — Triton, DeepStream, TRT-LLM
- [[onnx]] — формат обмена моделями, основной путь экспорта
- [[Polygraphy]] — инструмент отладки TRT графов
- [[Torch-TensorRT]] — PyTorch-нативная интеграция
- [[TensorRT-LLM]] — библиотека для LLM inference
- [[dynamic-quantization]] — смежная техника квантизации
- [[knowledge-distillation]] — альтернатива квантизации для компрессии

---

## References

- [NVIDIA TensorRT Docs](https://docs.nvidia.com/deeplearning/tensorrt/latest/index.html)
- [TRT Architecture Overview](https://docs.nvidia.com/deeplearning/tensorrt/latest/architecture/architecture-overview.html)
- [TRT 10.10.0 Release Notes](https://docs.nvidia.com/deeplearning/tensorrt/latest/getting-started/release-notes-10/10.10.0.html)
- [Torch-TensorRT Docs](https://docs.pytorch.org/TensorRT/)
- [Accelerating Inference 6× — NVIDIA Blog](https://developer.nvidia.com/blog/accelerating-inference-up-to-6x-faster-in-pytorch-with-torch-tensorrt/)

---
*Created: 2026-04-16 | Last verified: 2026-04-16*
