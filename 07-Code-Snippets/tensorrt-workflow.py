"""
TensorRT Workflow — переиспользуемые паттерны
=============================================
Теги: #approach/inference-optimization #tool/tensorrt
Создано: 2026-04-16
Источник: wiki/tensorrt.md

ОГЛАВЛЕНИЕ:
  1. Export PyTorch → ONNX
  2. ONNX → TRT Engine (Python API, FP16)
  3. ONNX → TRT Engine (Dynamic Shapes)
  4. INT8 Calibrator (Entropy)
  5. TRT Engine Inference (pycuda)
  6. Torch-TensorRT (torch.compile backend)
  7. trtexec — полезные CLI-команды
  8. Polygraphy — отладка и сравнение
"""

# ===========================================================================
# 1. Export PyTorch → ONNX
# ===========================================================================
import torch

def export_to_onnx(model, example_input, output_path="model.onnx", opset=17):
    """Экспорт торч-модели в ONNX с динамическим batch dim."""
    model.eval()
    torch.onnx.export(
        model,
        example_input,
        output_path,
        opset_version=opset,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input":  {0: "batch_size"},
            "output": {0: "batch_size"},
        },
        do_constant_folding=True,
    )
    print(f"Exported to {output_path}")

# Использование:
# model = torchvision.models.resnet50(pretrained=True).eval().cuda()
# export_to_onnx(model, torch.randn(1, 3, 224, 224).cuda())


# ===========================================================================
# 2. ONNX → TRT Engine (Python API, FP16, static shapes)
# ===========================================================================
import tensorrt as trt

def build_engine_fp16(onnx_path: str, engine_path: str, workspace_gb: int = 4):
    """Строим FP16 TRT движок из ONNX."""
    logger  = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser  = trt.OnnxParser(network, logger)

    with open(onnx_path, "rb") as f:
        if not parser.parse(f.read()):
            for i in range(parser.num_errors):
                print(parser.get_error(i))
            raise RuntimeError("ONNX parse failed")

    config = builder.create_builder_config()
    config.set_flag(trt.BuilderFlag.FP16)
    config.set_memory_pool_limit(
        trt.MemoryPoolType.WORKSPACE, workspace_gb * (1 << 30)
    )

    plan = builder.build_serialized_network(network, config)
    with open(engine_path, "wb") as f:
        f.write(plan)
    print(f"Engine saved to {engine_path}")


# ===========================================================================
# 3. ONNX → TRT Engine (Dynamic Shapes)
# ===========================================================================
def build_engine_dynamic(
    onnx_path: str,
    engine_path: str,
    input_name: str = "input",
    min_shape=(1, 3, 224, 224),
    opt_shape=(8, 3, 224, 224),
    max_shape=(32, 3, 224, 224),
    workspace_gb: int = 4,
):
    """TRT движок с поддержкой dynamic batch size."""
    logger  = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser = trt.OnnxParser(network, logger)

    with open(onnx_path, "rb") as f:
        parser.parse(f.read())

    config  = builder.create_builder_config()
    config.set_flag(trt.BuilderFlag.FP16)
    config.set_memory_pool_limit(
        trt.MemoryPoolType.WORKSPACE, workspace_gb * (1 << 30)
    )

    profile = builder.create_optimization_profile()
    profile.set_shape(input_name, min_shape, opt_shape, max_shape)
    config.add_optimization_profile(profile)

    plan = builder.build_serialized_network(network, config)
    with open(engine_path, "wb") as f:
        f.write(plan)
    print(f"Dynamic engine saved to {engine_path}")


# ===========================================================================
# 4. INT8 Entropy Calibrator
# ===========================================================================
import os
import numpy as np

class EntropyCalibrator(trt.IInt8EntropyCalibrator2):
    """Калибратор INT8 на NumPy-батчах."""

    def __init__(self, calib_data: list, cache_file: str = "int8_calib.cache"):
        """
        calib_data: список np.ndarray формы (C, H, W) или (B, C, H, W)
        """
        super().__init__()
        import pycuda.driver as cuda
        import pycuda.autoinit  # noqa: F401

        self.calib_data = calib_data
        self.cache_file = cache_file
        self.idx = 0

        # Аллоцируем GPU-буфер под один элемент датасета
        sample = np.ascontiguousarray(calib_data[0].astype(np.float32))
        self._buf = cuda.mem_alloc(sample.nbytes)
        self._cuda = cuda

    def get_batch_size(self): return 1

    def get_batch(self, names):
        if self.idx >= len(self.calib_data):
            return None
        item = np.ascontiguousarray(self.calib_data[self.idx].astype(np.float32))
        self._cuda.memcpy_htod(self._buf, item)
        self.idx += 1
        return [int(self._buf)]

    def read_calibration_cache(self):
        if os.path.exists(self.cache_file):
            with open(self.cache_file, "rb") as f:
                return f.read()
        return None

    def write_calibration_cache(self, cache):
        with open(self.cache_file, "wb") as f:
            f.write(cache)


def build_engine_int8(onnx_path, engine_path, calib_data, workspace_gb=4):
    """INT8 TRT движок с Entropy калибровкой."""
    logger  = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser = trt.OnnxParser(network, logger)
    with open(onnx_path, "rb") as f:
        parser.parse(f.read())

    config = builder.create_builder_config()
    config.set_flag(trt.BuilderFlag.INT8)
    config.set_memory_pool_limit(
        trt.MemoryPoolType.WORKSPACE, workspace_gb * (1 << 30)
    )
    config.int8_calibrator = EntropyCalibrator(calib_data)

    plan = builder.build_serialized_network(network, config)
    with open(engine_path, "wb") as f:
        f.write(plan)


# ===========================================================================
# 5. TRT Engine Inference (pycuda)
# ===========================================================================
import pycuda.driver as cuda
import pycuda.autoinit  # noqa: F401


class TRTInferenceEngine:
    """Обёртка для TRT inference с pycuda."""

    def __init__(self, engine_path: str):
        logger  = trt.Logger(trt.Logger.WARNING)
        runtime = trt.Runtime(logger)
        with open(engine_path, "rb") as f:
            self.engine = runtime.deserialize_cuda_engine(f.read())
        self.context = self.engine.create_execution_context()

        # Аллоцируем буферы
        self.inputs, self.outputs, self.bindings, self.stream = [], [], [], cuda.Stream()
        for binding in self.engine:
            size  = trt.volume(self.engine.get_binding_shape(binding))
            dtype = trt.nptype(self.engine.get_binding_dtype(binding))
            host_mem   = cuda.pagelocked_empty(size, dtype)
            device_mem = cuda.mem_alloc(host_mem.nbytes)
            self.bindings.append(int(device_mem))
            if self.engine.binding_is_input(binding):
                self.inputs.append({"host": host_mem, "device": device_mem})
            else:
                self.outputs.append({"host": host_mem, "device": device_mem})

    def infer(self, input_array: np.ndarray) -> np.ndarray:
        """Синхронный inference. input_array: float32 numpy."""
        np.copyto(self.inputs[0]["host"], input_array.ravel())
        # H2D
        cuda.memcpy_htod_async(self.inputs[0]["device"], self.inputs[0]["host"], self.stream)
        # Execute
        self.context.execute_async_v2(self.bindings, self.stream.handle, None)
        # D2H
        cuda.memcpy_dtoh_async(self.outputs[0]["host"], self.outputs[0]["device"], self.stream)
        self.stream.synchronize()
        return self.outputs[0]["host"].copy()


# ===========================================================================
# 6. Torch-TensorRT (torch.compile backend) — самый простой путь
# ===========================================================================

def compile_with_tensorrt(model, example_inputs, enabled_precisions=None):
    """
    Компиляция через torch.compile + TRT backend.
    Требует: pip install torch-tensorrt
    """
    import torch_tensorrt  # noqa: F401 (регистрирует backend)

    if enabled_precisions is None:
        enabled_precisions = {torch.float16}

    compiled = torch.compile(
        model,
        backend="tensorrt",
        options={
            "enabled_precisions": enabled_precisions,
            "truncate_long_and_double": True,
        },
    )
    # Warmup (компиляция происходит при первом вызове)
    with torch.no_grad():
        _ = compiled(*example_inputs)
    return compiled


# ===========================================================================
# 7. trtexec — полезные CLI-команды (комментарии)
# ===========================================================================
"""
# FP16 engine из ONNX
trtexec --onnx=model.onnx --fp16 --saveEngine=model_fp16.trt

# INT8 с калибровкой
trtexec --onnx=model.onnx --int8 --calib=calib_data/ --saveEngine=model_int8.trt

# Dynamic shapes
trtexec --onnx=model.onnx --fp16 \
  --minShapes=input:1x3x224x224 \
  --optShapes=input:8x3x224x224 \
  --maxShapes=input:32x3x224x224 \
  --saveEngine=model_dynamic.trt

# Профилирование готового движка
trtexec --loadEngine=model_fp16.trt --batch=8 --iterations=100

# Timing Cache для ускорения повторных сборок
trtexec --onnx=model.onnx --fp16 \
  --timingCacheFile=timing.cache \
  --saveEngine=model_fp16.trt

# FP8 (Hopper+)
trtexec --onnx=model.onnx --fp8 --saveEngine=model_fp8.trt
"""

# ===========================================================================
# 8. Polygraphy — отладка и сравнение ONNX vs TRT
# ===========================================================================
"""
# Установка
pip install polygraphy --extra-index-url https://pypi.ngc.nvidia.com

# Конвертация с автоматической FP16 оптимизацией
polygraphy convert model.onnx \
  --trt-min-shapes input:[1,3,224,224] \
  --trt-opt-shapes input:[8,3,224,224] \
  --trt-max-shapes input:[32,3,224,224] \
  -o model_trt.trt

# Сравнение ONNX (CPU/CUDA) vs TRT output
polygraphy run model.onnx \
  --onnxrt --trt \
  --save-results=results.json

# Анализ слоёв, упавших в точности при FP16
polygraphy debug precision model.onnx \
  --fp16 \
  --check-error-stat median
"""
