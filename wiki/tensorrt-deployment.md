---
created: 2026-04-16
source_date: 2025-01-01
last_verified: 2026-04-16
confidence_level: high
decay_rate: fast
status: current
tags: [type/wiki, approach/inference-optimization, approach/deployment]
aliases: [TRT Deployment, TensorRT Production]
---

# TensorRT — Deployment Patterns

> Паттерны деплоймента TRT-движков в продакшн: Triton Inference Server, DeepStream (видеоаналитика), TensorRT-LLM (крупные языковые модели).

Родительская статья: [[tensorrt]]

---

## Triton Inference Server

### Что это
NVIDIA Triton — multi-framework inference сервер с поддержкой TensorRT, ONNX Runtime, TensorFlow, PyTorch, Python backend. Предоставляет gRPC/HTTP API для multi-client serving.

### Преимущества vs запуска TRT напрямую

| Фича | Triton | Голый TRT |
|---|---|---|
| Dynamic batching | ✅ авто | ❌ ручной |
| Concurrent multi-model | ✅ | ❌ |
| Model versioning | ✅ | ❌ |
| gRPC/HTTP API | ✅ | ❌ |
| Multi-GPU | ✅ | Ручной |
| Metrics (Prometheus) | ✅ | ❌ |

### Структура репозитория моделей

```
model_repository/
└── resnet50/
    ├── config.pbtxt          ← конфигурация Triton
    └── 1/
        └── model.plan        ← TRT engine (*.trt / *.plan)
```

```protobuf
# config.pbtxt
name: "resnet50"
backend: "tensorrt"
max_batch_size: 32

input [{
  name: "input"
  data_type: TYPE_FP32
  dims: [3, 224, 224]
}]

output [{
  name: "output"
  data_type: TYPE_FP32
  dims: [1000]
}]

dynamic_batching {
  preferred_batch_size: [8, 16]
  max_queue_delay_microseconds: 100
}
```

### Запуск

```bash
# Docker (рекомендуется)
docker run --gpus all --rm \
  -p 8000:8000 -p 8001:8001 -p 8002:8002 \
  -v /path/to/model_repository:/models \
  nvcr.io/nvidia/tritonserver:25.01-py3 \
  tritonserver --model-repository=/models

# Клиент (Python)
import tritonclient.http as httpclient
client = httpclient.InferenceServerClient("localhost:8000")
result = client.infer("resnet50", inputs=[...])
```

### Поддерживаемые версии (актуально 2025)
- x86: Release 2.60.0 (NGC Container 26.01)
- Jetson: Release 2.56.0 (NGC Container 25.08)

---

## DeepStream

### Что это
NVIDIA SDK для потоковой видеоаналитики (real-time video pipeline). Использует GStreamer под капотом.

### Ключевые плагины для TensorRT

| Плагин | Описание |
|---|---|
| `Gst-nvinfer` | Нативный TRT inference внутри GStreamer pipeline |
| `Gst-nvinferserver` | TRT inference через Triton (gRPC); позволяет использовать все возможности Triton |

### Базовая схема DeepStream pipeline

```
filesrc / rtsp source
    │
    ▼
nvdecoder (NVDEC hardware decode)
    │
    ▼
nvstreammux (batching нескольких потоков)
    │
    ▼
nvinfer (TRT inference — детектор)
    │
    ▼
nvtracker (объектный трекинг)
    │
    ▼
nvinfer (TRT inference — классификатор)
    │
    ▼
nvdsosd (OSD overlay)
    │
    ▼
display / encoder / rtsp output
```

### Пример: nvinfer config

```ini
[property]
gpu-id=0
net-scale-factor=0.0039215697906911373
model-engine-file=resnet50_b1_gpu0_fp16.engine
labelfile-path=labels.txt
batch-size=1
network-mode=2          # 0=FP32, 1=INT8, 2=FP16
process-mode=1          # 1=primary detector, 2=secondary classifier
num-detected-classes=80
interval=0
```

### Производительность (типичные цифры)
- T4 GPU: ~32 FPS для ResNet-50 (TF-TRT оптимизация)
- Jetson AGX Xavier: ~15 FPS для ResNet-50
- Обработка 8+ RTSP-потоков 1080p на одном GPU (детектор типа YOLOv8)

---

## TensorRT-LLM

### Что это
Специализированная NVIDIA-библиотека для LLM inference на NVIDIA GPU. Построена поверх PyTorch, предоставляет high-level Python API + optimized CUDA kernels.

**Репозиторий**: [github.com/NVIDIA/TensorRT-LLM](https://github.com/NVIDIA/TensorRT-LLM)

### Ключевые оптимизации

| Техника | Описание |
|---|---|
| **Fused Multi-Head Attention** | Кастомный kernel для MHA с KV-кэшем |
| **In-flight Batching** | Динамическое пакетирование запросов разной длины |
| **PagedKV Cache** | Управление KV-кэшем по страницам (vLLM-стиль) |
| **Speculative Decoding** | Draft model + target model для ускорения генерации |
| **Tensor Parallelism** | Горизонтальный split матриц по GPU |
| **Pipeline Parallelism** | Разбивка слоёв по GPU |
| **Prefill-Decode Disaggregation** | Раздельные инстансы для prefill и decode фаз |
| **Wide Expert Parallelism (MoE)** | Параллелизм для Mixture-of-Experts моделей |

### Workflow: Llama → TRT-LLM

```bash
# Шаг 1: Конвертация весов
python convert_checkpoint.py \
  --model_dir ./llama-3-8b-hf \
  --output_dir ./trt_ckpt/llama3-8b \
  --dtype float16

# Шаг 2: Сборка TRT движка
trtllm-build \
  --checkpoint_dir ./trt_ckpt/llama3-8b \
  --output_dir ./trt_engines/llama3-8b \
  --gpt_attention_plugin float16 \
  --gemm_plugin float16 \
  --max_batch_size 32 \
  --max_input_len 2048 \
  --max_output_len 512

# Шаг 3: Inference (Python API)
from tensorrt_llm import LLM, SamplingParams

llm = LLM(model="./trt_engines/llama3-8b")
prompts = ["Explain transformers in ML:"]
outputs = llm.generate(prompts, SamplingParams(temperature=0.8, max_tokens=256))
```

### AutoDeploy (TRT-LLM 0.10+)
Автоматически извлекает граф вычислений из off-the-shelf HuggingFace модели без ручной конвертации:

```python
from tensorrt_llm import LLM
llm = LLM(model="meta-llama/Llama-3.1-8B-Instruct")  # Прямо из HF Hub
```

### Производительность TRT-LLM (H100 80GB)

| Модель | Метрика | Значение |
|---|---|---|
| Llama 3.1 8B | Throughput vs PyTorch | до 4× |
| Llama 3.1 8B | Per-token latency | <10ms |
| Llama 3.1 70B (TP=4) | Throughput | до 3× vs vLLM |
| Mistral 7B | INT4 WoQ speedup | ~8× vs FP16 |

> ⚠️ Числа зависят от batch size, sequence length, GPU конфигурации. `[NEEDS VERIFICATION]` для конкретных сценариев.
> `sota_as_of: 2025-01-01`

### Деплоймент TRT-LLM через Triton

```
Client (gRPC/HTTP)
    │
    ▼
Triton Inference Server
    ├── tensorrtllm (TRT-LLM runtime backend)
    ├── preprocessing (токенизатор)
    └── postprocessing (декодинг)
```

Официальный пример: [tensorrtllm_backend](https://github.com/triton-inference-server/tensorrtllm_backend)

---

## Сравнение паттернов деплоймента

| Сценарий | Рекомендуемый путь |
|---|---|
| Один сервис, один GPU, production | Triton + TRT engine |
| Real-time видеоаналитика | DeepStream + nvinfer |
| LLM serving (7B–70B+) | TRT-LLM + Triton |
| Edge / Jetson | TRT engine напрямую или DeepStream |
| Прототип / R&D | torch.compile + "tensorrt" backend |
| Multi-model ensemble | Triton (pipeline mode) |

---

## Related Concepts

- [[tensorrt]] — основная статья
- [[tensorrt-quantization]] — квантизация моделей перед деплоймантом
- [[layer-fusion]] — ключевая оптимизация внутри TRT
- [[TensorRT-LLM]] — полная статья по TRT-LLM
- [[triton-inference-server]] — полная статья по Triton
- [[deepstream]] — полная статья по DeepStream
- [[onnx]] — формат обмена моделями

---

## References

- [Triton Inference Server Docs](https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/)
- [DeepStream Dev Guide — gst-nvinferserver](https://docs.nvidia.com/metropolis/deepstream/dev-guide/text/DS_plugin_gst-nvinferserver.html)
- [TensorRT-LLM GitHub](https://github.com/NVIDIA/TensorRT-LLM)
- [TensorRT-LLM Backend for Triton](https://github.com/triton-inference-server/tensorrtllm_backend)
- [TRT-LLM Memory Usage](https://nvidia.github.io/TensorRT-LLM/reference/memory.html)

---
*Created: 2026-04-16 | Last verified: 2026-04-16*
