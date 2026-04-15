---
created: 2026-04-16
source_date: 2024-01-01
last_verified: 2026-04-16
confidence_level: high
decay_rate: slow
status: current
tags: [type/concept, approach/inference-optimization]
aliases: [Kernel Fusion, Op Fusion, Layer Merging]
---

# Layer Fusion

## Definition

> **Layer Fusion** (слияние слоёв) — оптимизация inference: несколько последовательных операций объединяются в один CUDA-kernel, исключая промежуточные записи/чтения из VRAM.

## How It Works

GPU-inference memory-bound: при раздельном выполнении каждый слой читает входной тензор из VRAM и пишет результат обратно. Fusion позволяет выполнить цепочку операций за одно обращение к памяти.

```
БЕЗ fusion:
  VRAM → [Conv kernel] → VRAM → [BN kernel] → VRAM → [ReLU kernel] → VRAM
  (3 read + 3 write = 6 VRAM transactions)

С fusion:
  VRAM → [Conv+BN+ReLU kernel] → VRAM
  (1 read + 1 write = 2 VRAM transactions)
```

### Типичные примеры fusion

| Паттерн | Название |
|---|---|
| Conv + BatchNorm + ReLU | CBR fusion |
| Conv + Bias + Activation | CBA fusion |
| MatMul + Add + Activation | Transformer FFN fusion |
| Multi-Head Attention (Q,K,V proj + softmax + V·attn) | MHA fusion |
| Norm + Linear | Pre-norm fusion |

### BatchNorm fusion с Conv (статическая)
После обучения BN параметры можно поглотить в веса Conv:

```
w_fused = w_conv * (gamma / sqrt(var + eps))
b_fused = beta - mean * gamma / sqrt(var + eps)
```

Это **статический fold** — происходит до runtime, делает BN нулевой стоимостью.

## Why It Matters

- Уменьшение **memory bandwidth** — главный bottleneck на GPU для небольших моделей
- Снижение **kernel launch overhead** (запуск CUDA-kernel стоит ~5–20μs)
- Лучшая утилизация **L2 cache** GPU
- В [[tensorrt]] fusion выполняется автоматически в стадии Optimization

## Variants / Extensions

- **Horizontal fusion** — объединение нескольких независимых conv/matmul одного размера в batched op
- **Vertical fusion** — цепочка последовательных операций (стандартный паттерн выше)
- **Flash Attention** — экстремальный вариант fusion для attention: устраняет материализацию матрицы attention (N×N)
- **Triton kernels** — ручная реализация fused kernels для нестандартных паттернов
- **torch.compile** — автоматическая fusion через inductor backend

## Examples in Models

- [[YOLOv8]] — Conv+BN+SiLU fusion во всех backbone слоях
- [[ResNet]] — CBR fusion в каждом residual block
- [[ViT]] — MHA fusion + LayerNorm+Linear fusion
- [[FLUX]] — Fused Attention ускоряет diffusion inference 2.4× через TRT

## Common Pitfalls

- **Training vs Inference**: BatchNorm нельзя сливать в training mode (он использует running stats)
- **Residual connections**: fusion не применима, если выход используется двумя ветками
- **Custom activations**: TRT может не поддерживать fusion для нестандартных activation functions
- **Dynamic shapes**: некоторые fused kernels оптимальны только для конкретных shapes

## Related Concepts

- [[tensorrt]] — главный потребитель fusion в NVIDIA-экосистеме
- [[layer-fusion]] (self)
- [[flash-attention]] — extreme fusion для attention
- [[tensorrt-quantization]] — complementary оптимизация
- [[torch-compile]] — fusion в PyTorch ecosystem
- [[onnx]] — промежуточный формат, где fusion применяется при конвертации

## References

- [TensorRT Optimization Overview](https://docs.nvidia.com/deeplearning/tensorrt/latest/architecture/architecture-overview.html)
- [Flash Attention Paper (Dao et al., 2022)](https://arxiv.org/abs/2205.14135)
- [Triton: Blocked Algorithms for Neural Network Computations](https://www.eecs.harvard.edu/~htk/publication/2019-mapl-tillet-kung-cox.pdf)

---
*Created: 2026-04-16*
