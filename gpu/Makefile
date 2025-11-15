################################################################################
# Makefile for DFVG GPU Verify Engine
# Compiles CUDA/C++ kernels and produces a shared library:
#     build/libverify_gpu.so
################################################################################

# ==== Directories =============================================================

SRC_DIR      := src
BUILD_DIR    := build
INCLUDE_DIRS := include

# ==== Compiler & Flags ========================================================

NVCC := nvcc
CXX  := g++

CUDA_ARCH     := -gencode arch=compute_80,code=sm_80 \
                 -gencode arch=compute_86,code=sm_86 \
                 -gencode arch=compute_89,code=sm_89

NVCC_FLAGS    := -O3 -lineinfo -Xcompiler -fPIC $(CUDA_ARCH)
CXX_FLAGS     := -O3 -fPIC -std=c++17

INCLUDES      := $(addprefix -I, $(INCLUDE_DIRS))

# ==== Source Files ============================================================

CUDA_SRCS := $(wildcard $(SRC_DIR)/*.cu)
CPP_SRCS  := $(wildcard $(SRC_DIR)/*.cpp)

CUDA_OBJS := $(patsubst $(SRC_DIR)/%.cu,$(BUILD_DIR)/%.o,$(CUDA_SRCS))
CPP_OBJS  := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(CPP_SRCS))

OBJS := $(CUDA_OBJS) $(CPP_OBJS)

TARGET := $(BUILD_DIR)/libverify_gpu.so

# ==== Rules ===================================================================

all: $(TARGET)
	@echo "[OK] GPU build completed."

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cu | $(BUILD_DIR)
	@echo "[NVCC] Compiling $<"
	$(NVCC) $(NVCC_FLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@echo "[C++] Compiling $<"
	$(CXX) $(CXX_FLAGS) $(INCLUDES) -c $< -o $@

$(TARGET): $(OBJS)
	@echo "[LINK] Creating shared library -> $@"
	$(NVCC) -shared -Xcompiler -fPIC $(OBJS) -o $@

clean:
	rm -rf $(BUILD_DIR)
	@echo "[CLEAN] Build directory removed."

rebuild: clean all

# ==== Phony Targets ===========================================================

.PHONY: all clean rebuild

