## Internal tips how to compile Whisperx, Docling and maybe Pytorch from scratch on Termux. 
Version 2.3

Why the below is needed? To use `whisperx` for example, which needs recondite library files, ex. distributed PyTorch. 

* apt install python-onxxruntime
* apt install python-torch
* apt install whisperx
* apt install libspatialindex


#Docling:
* See: https://github.com/docling-project/docling-parse/issues/122#issuecomment-2960123587: `patchelf --add-needed libpython3.12.so.1.0 /data/data/com.termux/files/usr/lib/python3.12/site-packages/docling_parse/pdf_parsers.cpython-312.so`

#Whisperx: 
* Remove distributed Pytorch mentions: 
```
sed -i '/import torch.distributed.tensor/c\
try:\
    import torch.distributed.tensor\
except ImportError:\
    pass' /data/data/com.termux/files/usr/lib/python3.12/site-packages/transformers/modeling_utils.py
```

and 
```
sed -i '/import torch\.distributed\.tensor/c\
try:\
    import torch.distributed.tensor\
except ImportError:\
    pass' /data/data/com.termux/files/usr/lib/python3.12/site-packages/transformers/model_debugging_utils.py
```
#The code must contain spaces

* Remove too specific: ` Wav2Vec2ForCTC, Wav2Vec2Processor` imports: 
`sed -i 's|from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor|from transformers import *|' /data/data/com.termux/files/usr/lib/python3.12/site-packages/whisperx/alignment.py`

* Increase memory : 
```
ulimit -s
ulimit -n
echo Increasing them... 
ulimit -s 65536
sudo ulimit -n 16384

echo

ulimit -s
ulimit -n
```


* Run `whisperx --compute_type float32 ` ...  
# all other compute types crash via segmentation fault. 



## Draft notws if you tried to install Pytorch from scratch on Termux: 

1. `git clone --recursive https://github.com/pytorch/pytorch`
2. `git submodule update --init --recursive`
3. If playing up, go to `cd third_party` and: 
A. git clone https://github.com/mreineck/pocketfft
B. git clone https://github.com/Maratyszcza/psimd.git

Then: 
`sed -i 's/#if (__cplusplus >= 201703L) && (!defined(__MINGW32__)) && (!defined(_MSC_VER))/#if (__cplusplus >= 201703L) && (!defined(__MINGW32__)) && (!defined(_MSC_VER)) && (!defined(__ANDROID__))/g' /data/data/com.termux/files/home/downloads/pytorch/third_party/pocketfft/pocketfft_hdronly.h`

Use `make -j4` , at the modest parallelism. 

Check if no errors:
```
-- Brace yourself, we are building NNPACK
CMake Deprecation Warning at third_party/NNPACK/CMakeLists.txt:1 (CMAKE_MINIMUM_REQUIRED):
  Compatibility with CMake < 3.10 will be removed from a future version of
  CMake.

  Update the VERSION argument <min> value.  Or, use the <min>...<max> syntax
  to tell CMake that the project requires at least <min> but has been updated
  to work with policies introduced by <max> or earlier.


-- NNPACK backend is neon
-- Using ccache: /data/data/com.termux/files/usr/bin/ccache
-- Building for XNNPACK_TARGET_PROCESSOR: arm64
-- Found Python: /data/data/com.termux/files/usr/bin/python3.12 (found version "3.12.10") found components: Interpreter
-- Generating microkernels.cmake
Duplicate microkernel definition: src/qs8-qc4w-packw/gen/qs8-qc4w-packw-x8c8-gemm-goi-avx256vnni.c and src/qs8-qc4w-packw/gen/qs8-qc4w-packw-x8c8-gemm-goi-avxvnni.c (1th function)
Duplicate microkernel definition: src/qs8-qc4w-packw/gen/qs8-qc4w-packw-x8c8-gemm-goi-avxvnni.c and src/qs8-qc4w-packw/gen/qs8-qc4w-packw-x8c8-gemm-goi-scalar.c
No microkernel found in src/reference/binary-elementwise.cc
No microkernel found in src/reference/packing.cc
No microkernel found in src/reference/unary-elementwise.cc
CMake Warning at cmake/Dependencies.cmake:711 (message):
  Turning USE_FAKELOWP off as it depends on USE_FBGEMM.
Call Stack (most recent call first):
  CMakeLists.txt:863 (include)


-- Using third party subdirectory Eigen.
-- Setting Python to /data/data/com.termux/files/usr/bin/python3
-- Found Python: /data/data/com.termux/files/usr/bin/python3 (found version "3.12.10") found components: Interpreter
-- Using third_party/pybind11.
-- pybind11 include dirs: /data/data/com.termux/files/home/downloads/pytorch/cmake/../third_party/pybind11/include
-- Could NOT find OpenTelemetryApi (missing: OpenTelemetryApi_INCLUDE_DIRS) 
-- Using third_party/opentelemetry-cpp.
-- opentelemetry api include dirs: /data/data/com.termux/files/home/downloads/pytorch/cmake/../third_party/opentelemetry-cpp/api/include
-- Check OMP with lib /data/data/com.termux/files/usr/lib/libomp.a and flags -fopenmp=libomp -v
-- Check OMP with lib /data/data/com.termux/files/usr/lib/libomp.a and flags -fopenmp=libomp -v
-- Found OpenMP_C: -fopenmp=libomp
-- Found OpenMP_CXX: -fopenmp=libomp
-- Found OpenMP: TRUE
-- Adding OpenMP CXX_FLAGS: -fopenmp=libomp
-- Will link against OpenMP libraries: /data/data/com.termux/files/usr/lib/libomp.a
-- Found nvtx3: /data/data/com.termux/files/home/downloads/pytorch/third_party/NVTX/c/include
-- {fmt} version: 11.2.0
-- Build type: Release
-- Performing Test HAS_NULLPTR_WARNING
-- Performing Test HAS_NULLPTR_WARNING - Success
-- Not using libkineto in a mobile build.
-- Performing Test HAS_WERROR_RETURN_TYPE
-- Performing Test HAS_WERROR_RETURN_TYPE - Success
-- Performing Test HAS_WERROR_NON_VIRTUAL_DTOR
-- Performing Test HAS_WERROR_NON_VIRTUAL_DTOR - Success
-- Performing Test HAS_WERROR_BRACED_SCALAR_INIT
-- Performing Test HAS_WERROR_BRACED_SCALAR_INIT - Success
-- Performing Test HAS_WERROR_RANGE_LOOP_CONSTRUCT
-- Performing Test HAS_WERROR_RANGE_LOOP_CONSTRUCT - Success
-- Performing Test HAS_WERROR_BOOL_OPERATION
-- Performing Test HAS_WERROR_BOOL_OPERATION - Success
-- Performing Test HAS_WNARROWING
-- Performing Test HAS_WNARROWING - Success
-- Performing Test HAS_WNO_MISSING_FIELD_INITIALIZERS
-- Performing Test HAS_WNO_MISSING_FIELD_INITIALIZERS - Success
-- Performing Test HAS_WNO_UNKNOWN_PRAGMAS
-- Performing Test HAS_WNO_UNKNOWN_PRAGMAS - Success
-- Performing Test HAS_WNO_UNUSED_PARAMETER
-- Performing Test HAS_WNO_UNUSED_PARAMETER - Success
-- Performing Test HAS_WNO_STRICT_OVERFLOW
-- Performing Test HAS_WNO_STRICT_OVERFLOW - Success
-- Performing Test HAS_WNO_STRICT_ALIASING
-- Performing Test HAS_WNO_STRICT_ALIASING - Success
-- Performing Test HAS_WNO_STRINGOP_OVERFLOW
-- Performing Test HAS_WNO_STRINGOP_OVERFLOW - Failed
-- Performing Test HAS_WVLA_EXTENSION
-- Performing Test HAS_WVLA_EXTENSION - Success
-- Performing Test HAS_WSUGGEST_OVERRIDE
-- Performing Test HAS_WSUGGEST_OVERRIDE - Success
-- Performing Test HAS_WNEWLINE_EOF
-- Performing Test HAS_WNEWLINE_EOF - Success
-- Performing Test HAS_WINCONSISTENT_MISSING_OVERRIDE
-- Performing Test HAS_WINCONSISTENT_MISSING_OVERRIDE - Success
-- Performing Test HAS_WINCONSISTENT_MISSING_DESTRUCTOR_OVERRIDE
-- Performing Test HAS_WINCONSISTENT_MISSING_DESTRUCTOR_OVERRIDE - Success
-- Performing Test HAS_WNO_ERROR_OLD_STYLE_CAST
-- Performing Test HAS_WNO_ERROR_OLD_STYLE_CAST - Success
-- Performing Test HAS_WCONSTANT_CONVERSION
-- Performing Test HAS_WCONSTANT_CONVERSION - Success
-- Performing Test HAS_WNO_ALIGNED_ALLOCATION_UNAVAILABLE
-- Performing Test HAS_WNO_ALIGNED_ALLOCATION_UNAVAILABLE - Failed
-- Performing Test HAS_QUNUSED_ARGUMENTS
-- Performing Test HAS_QUNUSED_ARGUMENTS - Success
-- Performing Test HAS_FCOLOR_DIAGNOSTICS
-- Performing Test HAS_FCOLOR_DIAGNOSTICS - Success
-- Performing Test HAS_FALIGNED_NEW
-- Performing Test HAS_FALIGNED_NEW - Success
-- Performing Test HAS_WNO_MAYBE_UNINITIALIZED
-- Performing Test HAS_WNO_MAYBE_UNINITIALIZED - Failed
-- Performing Test HAS_FSTANDALONE_DEBUG
-- Performing Test HAS_FSTANDALONE_DEBUG - Success
-- Performing Test HAS_FNO_MATH_ERRNO
-- Performing Test HAS_FNO_MATH_ERRNO - Success
-- Performing Test HAS_FNO_TRAPPING_MATH
-- Performing Test HAS_FNO_TRAPPING_MATH - Success
-- Performing Test HAS_WERROR_FORMAT
-- Performing Test HAS_WERROR_FORMAT - Success
-- Performing Test HAS_VST1
-- Performing Test HAS_VST1 - Success
-- Performing Test HAS_VLD1
-- Performing Test HAS_VLD1 - Success
-- don't use NUMA
-- Looking for backtrace
-- Looking for backtrace - not found
-- Could NOT find Backtrace (missing: Backtrace_LIBRARY Backtrace_INCLUDE_DIR) 
-- headers outputs: 
-- sources outputs: 
-- declarations_yaml outputs: 
-- Using ATen parallel backend: NATIVE
disabling CUDA because USE_CUDA is set false
-- Looking for clock_gettime in rt
-- Looking for clock_gettime in rt - found
-- Looking for mmap
-- Looking for mmap - found
-- Looking for shm_open
-- Looking for shm_open - not found
-- Looking for shm_unlink
-- Looking for shm_unlink - not found
-- Looking for malloc_usable_size
-- Looking for malloc_usable_size - found
AT_INSTALL_INCLUDE_DIR include/ATen/core
core header install: /data/data/com.termux/files/home/downloads/pytorch/build/aten/src/ATen/core/TensorBody.h
core header install: /data/data/com.termux/files/home/downloads/pytorch/build/aten/src/ATen/core/aten_interned_strings.h
core header install: /data/data/com.termux/files/home/downloads/pytorch/build/aten/src/ATen/core/enum_tag.h
-- Performing Test HAS_WMISSING_PROTOTYPES
-- Performing Test HAS_WMISSING_PROTOTYPES - Success
-- Performing Test HAS_WERROR_MISSING_PROTOTYPES
-- Performing Test HAS_WERROR_MISSING_PROTOTYPES - Success
CMake Warning at CMakeLists.txt:1276 (message):
  Generated cmake files are only fully tested if one builds with system glog,
  gflags, and protobuf.  Other settings may generate files that are not well
  tested.


-- 
-- ******** Summary ********
-- General:
--   CMake version         : 3.31.6
--   CMake command         : /data/data/com.termux/files/usr/bin/cmake
--   System                : Android
--   C++ compiler          : /data/data/com.termux/files/usr/bin/clang++
--   C++ compiler id       : Clang
--   C++ compiler version  : 20.1.5
--   Using ccache if found : ON
--   Found ccache          : /data/data/com.termux/files/usr/bin/ccache
--   CXX flags             :  -ffunction-sections -fdata-sections -fvisibility-inlines-hidden -DUSE_PTHREADPOOL -DUSE_PYTORCH_QNNPACK -DUSE_XNNPACK -DSYMBOLICATE_MOBILE_DEBUG_HANDLE -O2 -fPIC -DC10_NODEPRECATED -Wall -Wextra -Werror=return-type -Werror=non-virtual-dtor -Werror=braced-scalar-init -Werror=range-loop-construct -Werror=bool-operation -Wnarrowing -Wno-missing-field-initializers -Wno-unknown-pragmas -Wno-unused-parameter -Wno-strict-overflow -Wno-strict-aliasing -Wvla-extension -Wsuggest-override -Wnewline-eof -Winconsistent-missing-override -Winconsistent-missing-destructor-override -Wno-pass-failed -Wno-error=old-style-cast -Wconstant-conversion -Qunused-arguments -fcolor-diagnostics -faligned-new -fno-math-errno -fno-trapping-math -Werror=format -g0
--   Shared LD flags       : -llog -largp -lm -rdynamic
--   Static LD flags       : 
--   Module LD flags       : -llog -largp -lm
--   Build type            : Release
--   Compile definitions   : 
--   CMAKE_PREFIX_PATH     : 
--   CMAKE_INSTALL_PREFIX  : /data/data/com.termux/files/usr
--   USE_GOLD_LINKER       : OFF
-- 
--   TORCH_VERSION         : 2.8.0
--   BUILD_STATIC_RUNTIME_BENCHMARK: OFF
--   BUILD_BINARY          : OFF
--   BUILD_CUSTOM_PROTOBUF : ON
--     Link local protobuf : ON
--   BUILD_PYTHON          : OFF
--   BUILD_SHARED_LIBS     : ON
--   CAFFE2_USE_MSVC_STATIC_RUNTIME     : OFF
--   BUILD_TEST            : OFF
--   BUILD_JNI             : OFF
--   BUILD_MOBILE_AUTOGRAD : OFF
--   BUILD_LITE_INTERPRETER: OFF
--   INTERN_BUILD_MOBILE   : ON
--   TRACING_BASED         : OFF
--   USE_BLAS              : 1
--     BLAS                : 
--     BLAS_HAS_SBGEMM     : 
--   USE_LAPACK            : 0
--   USE_ASAN              : OFF
--   USE_TSAN              : OFF
--   USE_CPP_CODE_COVERAGE : OFF
--   USE_CUDA              : OFF
--   USE_XPU               : OFF
--   USE_ROCM              : OFF
--   BUILD_NVFUSER         : 
--   USE_EIGEN_FOR_BLAS    : ON
--   USE_FBGEMM            : OFF
--     USE_FAKELOWP          : OFF
--   USE_KINETO            : OFF
--   USE_GFLAGS            : OFF
--   USE_GLOG              : OFF
--   USE_LITE_PROTO        : OFF
--   USE_PYTORCH_METAL     : OFF
--   USE_PYTORCH_METAL_EXPORT     : OFF
--   USE_MPS               : OFF
--   CAN_COMPILE_METAL     : 
--   USE_MKL               : 
--   USE_MKLDNN            : OFF
--   USE_UCC               : OFF
--   USE_ITT               : OFF
--   USE_XCCL              : OFF
--   USE_NCCL              : OFF
--   USE_NNPACK            : ON
--   USE_NUMPY             : ON
--   USE_OBSERVERS         : OFF
--   USE_OPENCL            : OFF
--   USE_OPENMP            : ON
--   USE_MIMALLOC          : OFF
--   USE_VULKAN            : OFF
--   USE_PROF              : OFF
--   USE_PYTORCH_QNNPACK   : ON
--   USE_XNNPACK           : ON
--   USE_DISTRIBUTED       : OFF
--   Public Dependencies  : 
--   Private Dependencies : Threads::Threads;eigen_blas;pthreadpool;cpuinfo;pytorch_qnnpack;nnpack;XNNPACK;microkernels-prod;fp16;caffe2::openmp;log;fmt::fmt-header-only;dl
--   Public CUDA Deps.    : 
--   Private CUDA Deps.   : 
--   USE_COREML_DELEGATE     : OFF
--   BUILD_LAZY_TS_BACKEND   : OFF
--   USE_ROCM_KERNEL_ASSERT : OFF
-- Configuring done (50.3s)
-- Generating done (2.3s)
-- Build files have been written to: /data/data/com.termux/files/home/downloads/pytorch/build
~/.../pytorch/build $ 

```

What it means, pacem ChatGPT AD 2025: 
 
## 🔧 Major Build Characteristics

### ✅ Mobile-Oriented

* `INTERN_BUILD_MOBILE=ON` with `BUILD_LAZY_TS_BACKEND=OFF`, `BUILD_LITE_INTERPRETER=OFF`, `BUILD_MOBILE_AUTOGRAD=OFF`.
* **Implication**: This is a **minimalist backend**, sacrificing flexibility for binary size and performance on mobile. No eager-mode autograd, no TorchScript runtime, no lazy execution engine.

### ✅ CPU-Focused, NO GPU

* `USE_CUDA=OFF`, `USE_XPU=OFF`, `USE_ROCM=OFF`, `USE_VULKAN=OFF`.
* **Implication**: This build is entirely CPU-centric — no GPU, Vulkan, Metal, or SYCL compute paths. Vulkan off is explicit and respected.

---

## ⚙️ Backend Support & Kernel Strategies

### 🟢 **NNPACK ON**

* NNPACK is **enabled**, using the `neon` backend.
* It’s optimized for *inference*, esp. on **ARM NEON** SIMD — e.g. conv layers in image models.
* **Risks**: Some kernel definitions are duplicate, and some source files have no microkernels (`reference/*.cc`). These won't crash the build but signal **missing fast paths** or **fallback-only behavior**.

### 🟢 **XNNPACK ON**

* `USE_XNNPACK=ON`, targeted at `arm64`. XNNPACK is crucial for **quantized and low-precision inference**.
* Duplicate kernel warnings are **internal generation quirks**, not runtime blockers.

### 🔴 **FBGEMM OFF**

* `USE_FBGEMM=OFF` ⇒ `USE_FAKELOWP=OFF`.
* FBGEMM is often default on x86 — so this is expected, but important: **no fake low precision kernels**.
* In mobile CPU builds, this is standard.

### 🟢 **OpenMP ON**

* `libomp.a` found and linked.
* Ensures **threaded CPU ops** — big perf win on multicore arm64.

---

## ⚠️ Warnings, Pitfalls, and Fallbacks

### ⚠️ **NEON and SIMD Checks**

* NEON supported, but:

  * `Compiler does not support SVE extension` → SVE-only paths are excluded (okay unless targeting ARMv9+).
  * No OMAP-specific optimizations detected (ancient SoCs — ignorable today).

### ⚠️ **Microkernel Duplicates**

* Warnings like:

  ```
  Duplicate microkernel definition: ...-avx256vnni.c and ...-avxvnni.c
  ```

  ⇒ These refer to x86 AVX VNNI kernels which **don’t apply to arm64**, but the gen script still enumerates them.
  → Harmless unless it triggers build confusion (which your config avoids).

### ⚠️ **No Backtrace, No SHM**

* `shm_open`, `shm_unlink` not found — expected in Termux.
* `backtrace` also missing — minor debugging loss, no runtime issue.

---

## 🔍 Clean Confirmations

* `USE_VULKAN: OFF` ✅ confirmed
* `USE_OPENCL: OFF`, `USE_MPS: OFF`, `USE_METAL: OFF` ⇒ no accidental GPU paths
* `USE_GLOG`, `USE_GFLAGS`, `USE_OBSERVERS`, `USE_DISTRIBUTED`: all **OFF** ⇒ stripped of heavy infra.

---

## 🧪 Compiler Flags and Safety Checks

* Warnings enabled and many marked as `Werror=...`: forces compile-time hygiene.
* Several warnings fail, but not fatal:

  * `Wno-stringop-overflow` → warning support missing (clang 20 may not recognize some flags).
  * `Wno-aligned-allocation-unavailable`, `Wno-maybe-uninitialized`: disabled, but not critical.

---

## 🧠 Summary

This is a **lean, inference-optimized CPU build for ARM64 on Android**, explicitly avoiding:

* All GPU/Vulkan/Metal acceleration
* All training/autograd infra
* All distributed/observer/telemetry cruft

And embracing:

* NEON SIMD kernels (via NNPACK/XNNPACK)
* Static protobuf
* OpenMP threading
* Clean C++ hygiene (modern warnings, CMake ≥3.10 readiness)

---

## ✅ Recommended Actions Before `make`

1. **Monitor RAM during build**: Link time might spike due to large template usage (especially in ATen and Eigen). You’re on Android; use `proot` or swap as needed.
2. **Watch for `make -j` parallelism**: Don’t overthread on small RAM devices — start conservative (`-j2` or `-j3`).
3. **Post-Build Validation**: When done, test the binary using:

   ```bash
   ldd build/lib/libtorch_cpu.so | grep not
   ```
