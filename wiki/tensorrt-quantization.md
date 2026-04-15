---
created: 2026-04-16
source_date: 2025-01-01
last_verified: 2026-04-16
confidence_level: high
decay_rate: medium
status: current
tags: [type/wiki, type/concept, approach/quantization, approach/inference-optimization]
aliases: [TRT Quantization, INT8 Calibration, TensorRT INT8]
---

# TensorRT Quantization

> Квантизация в TensorRT — снижение разрядности весов и/или активаций для ускорения inference. Главный инструмент для максимального прироста производительности при допустимой деградации точности.

Родительская статья: [[tensorrt]]

---

## Поддерживаемые форматы

| Формат | Разрядность | Диапазон | Типичный speedup | Архитектура GPU |
|---|---|---|---|---|
| FP32 | 4B float | ~1.2e-38 .. 3.4e38 | 1× (baseline) | Всё |
| FP16 | 2B float | ~6e-8 .. 65504 | 2–3× | Volta+ (V100+) |
| BF16 | 2B float | ~1.2e-38 .. 3.4e38 | ~2× | Ampere+ (A100+) |
| INT8 | 1B int | -128 .. 127 | 3–6× | Всё (калибровка обязательна) |
| FP8 (E4M3/E5M2) | 1B float | ~1.2e-9 .. 448 | ~4× | Hopper+ (H100+) |
| INT4 WoQ | 0.5B int | -8 .. 7 | 4–8× весов | Hopper+ (веса LLM) |

> `WoQ` = Weight-only Quantization: веса хранятся в INT4, активации остаются в FP16/BF16.

---

## Post-Training Quantization (PTQ)

### Принцип
Квантизация **после обучения**, без дообучения. Требуется только небольшой калибрационный датасет (100–1000 семплов).

**Схема:**
```
FP32 model
    │
    ▼
Прогнать калибрационный датасет (forward pass)
    │
    ▼
Собрать статистику активаций по каждому слою
    │
    ▼
Вычислить scale/zero_point для каждого тензора
    │
    ▼
INT8 / FP8 engine
```

### Методы калибровки INT8

| Метод | Описание | Применение |
|---|---|---|
| **Max** | `scale = max(abs(tensor))` | Простой, но переоценивает диапазон при выбросах |
| **Entropy (KL)** | Минимизирует KL-divergence между FP32 и INT8 распределениями | **Default в TRT**, баланс точности и диапазона |
| **Percentile** | `scale = percentile(abs(tensor), 99.99)` | Устойчив к выбросам |
| **SmoothQuant** | Балансирует сложность квантизации между весами и активациями | Трансформеры с высокими выбросами активаций |
| **AWQ** | Adaptive Weight Quantization, настраивает scale-groups весов | LLM, INT4 |

### Реализация PTQ в TensorRT

```python
import tensorrt as trt

class MyCalibratorINT8(trt.IInt8EntropyCalibrator2):
    def __init__(self, dataset, cache_file="calibration.cache"):
        super().__init__()
        self.dataset   = dataset
        self.cache_file = cache_file
        self.idx       = 0
        # Выделяем GPU-буфер под один батч
        import pycuda.driver as cuda
        self.device_input = cuda.mem_alloc(dataset[0].nbytes)

    def get_batch_size(self): return 1

    def get_batch(self, names):
        if self.idx >= len(self.dataset):
            return None
        import pycuda.driver as cuda, numpy as np
        data = self.dataset[self.idx].astype(np.float32)
        cuda.memcpy_htod(self.device_input, data)
        self.idx += 1
        return [int(self.device_input)]

    def read_calibration_cache(self):
        if os.path.exists(self.cache_file):
            with open(self.cache_file, "rb") as f:
                return f.read()

    def write_calibration_cache(self, cache):
        with open(self.cache_file, "wb") as f:
            f.write(cache)

# Использование
config = builder.create_builder_config()
config.set_flag(trt.BuilderFlag.INT8)
config.int8_calibrator = MyCalibratorINT8(calib_dataset)
engine = builder.build_serialized_network(network, config)
```

---

## Quantization-Aware Training (QAT)

### Принцип
Симулирует квантизацию **во время обучения**: QDQ (Quantize/Dequantize) узлы вставляются в граф, и модель обучается учитывать округление.

**Схема:**
```
Pretrained FP32 model
    │
    ▼
Вставить QDQ-узлы (Q→DQ вокруг весов и активаций)
    │
    ▼
Fine-tuning с Straight-Through Estimator (STE)
    │
    ▼
ONNX export с QDQ-узлами
    │
    ▼
TRT engine (нативно читает QDQ → INT8 execution)
```

### Когда выбирать QAT vs PTQ

| Критерий | PTQ | QAT |
|---|---|---|
| Требует переобучения | ❌ Нет | ✅ Да |
| Сложность реализации | Низкая | Высокая |
| Accuracy при INT8 | Умеренная | Выше (особенно <1% drop) |
| Применимость | Большинство моделей | Точность критична |
| LLM | INT8 PTQ + SmoothQuant | QAT для FP8 (H100) |

### Инструменты QAT

- **TensorRT Model Optimizer** (`nvidia-modelopt`) — единая библиотека: QAT, PTQ, pruning, distillation
- **pytorch-quantization** (устаревший, заменён Model Optimizer)
- **Brevitas** — сторонняя библиотека QAT

```python
# TensorRT Model Optimizer (актуально 2025)
import modelopt.torch.quantization as mtq

# PTQ одной строкой
mtq.quantize(model, quant_cfg=mtq.INT8_DEFAULT_CFG, forward_loop=calib_forward)

# Экспорт в ONNX с QDQ-узлами для TRT
import modelopt.torch.export as mte
mte.export_tensorrt_llm_checkpoint(model, ...)
```

---

## INT8 в деталях

### Scale и Zero-Point
Линейное квантизирование: `x_q = clamp(round(x / scale + zero_point), -128, 127)`

TensorRT использует **симметричное** (zero_point=0) для весов и **асимметричное** для активаций.

### Per-tensor vs Per-channel
- **Per-tensor**: один scale на весь тензор — быстрее, менее точно
- **Per-channel**: отдельный scale для каждого output-канала весов — точнее (TRT поддерживает)
- **Per-group (block)**: scale на группу веса — INT4 WoQ для LLM

### QDQ-узлы в ONNX
TRT 8+ нативно интерпретирует `QuantizeLinear / DequantizeLinear` из ONNX opset 13 как INT8 операции:

```
                 ┌──────────┐
FP32 input → Q → │ INT8 Conv│ → DQ → FP32 output
             ↑   └──────────┘   ↑
           scale               scale
```

---

## FP8 (Hopper+, H100/H200)

FP8 имеет два варианта:
- **E4M3** (4 бита экспоненты, 3 мантиссы) — лучше для весов, узкий диапазон
- **E5M2** (5 бит экспоненты, 2 мантиссы) — лучше для градиентов / активаций

TensorRT поддерживает FP8 начиная с версии 8.6+ на Hopper. Типичный speedup ~4× vs FP32.

```bash
# FP8 через trtexec
trtexec --onnx=model.onnx --fp8 --calib=data/ --saveEngine=model_fp8.trt
```

---

## INT4 Weight-Only Quantization (LLM)

**Сценарий**: огромные LLM (7B+ параметров) — память веса доминирует над compute. INT4 WoQ снижает footprint весов в 8×.

```
Веса: FP16 → INT4  (4x меньше памяти)
Активации: остаются FP16

При inference: INT4 веса → online dequant → FP16 GEMM
```

**Block quantization** (TRT 10+): scale задаётся для группы 64/128 весов → выше точность, чем per-tensor.

Инструменты: [[TensorRT Model Optimizer]], [[AutoAWQ]], [[GPTQ]]

---

## Практические рекомендации

1. **Начинай с FP16** — минимальные усилия, 2–3× прирост, почти нулевые потери accuracy
2. **PTQ INT8** — если FP16 недостаточно быстро; обязательно: репрезентативный калибрационный датасет (≥500 семплов из реального распределения)
3. **QAT** — только если PTQ INT8 даёт >1–2% падение метрики
4. **FP8** — только H100/H200; для LLM и диффузионных моделей
5. **INT4 WoQ** — только для LLM, где bottleneck — память весов, а не compute
6. Используй [[Polygraphy]] для анализа слоёв, упавших в точности

---

## Related Concepts

- [[tensorrt]] — основная статья
- [[tensorrt-deployment]] — деплоймент с квантизованными моделями
- [[layer-fusion]] — смежная оптимизация
- [[knowledge-distillation]] — альтернатива квантизации
- [[onnx]] — формат экспорта с QDQ-узлами
- [[Polygraphy]] — инструмент отладки precision issues
- [[TensorRT Model Optimizer]] — официальный инструмент квантизации

---

## References

- [TRT Working with Quantized Types](https://docs.nvidia.com/deeplearning/tensorrt/latest/inference-library/work-quantized-types.html)
- [Torch-TRT PTQ Guide](https://docs.pytorch.org/TensorRT/ts/ptq.html)
- [TensorRT Model Optimizer Docs](https://nvidia.github.io/TensorRT-Model-Optimizer/)
- [Optimizing LLMs with PTQ — NVIDIA Blog](https://developer.nvidia.com/blog/optimizing-llms-for-performance-and-accuracy-with-post-training-quantization/)
- [SmoothQuant Paper (Xiao et al., 2022)](https://arxiv.org/abs/2211.10438)

---
*Created: 2026-04-16 | Last verified: 2026-04-16*
