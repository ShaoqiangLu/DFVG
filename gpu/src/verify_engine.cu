// gpu/src/verify_engine.cu
#include "verify_engine.h"

#include <cuda_runtime.h>
#include <vector>
#include <iostream>
#include <stdexcept>
#include <cstdio>

// Declare the kernel launcher from kernels.cu
void launch_verify_kernel(
    const float* d_logits,
    std::size_t  batch_size,
    std::size_t  vocab_size,
    int*         d_accepted,
    cudaStream_t stream
);

// Very minimal global state (for demo purposes)
static VerifyConfig g_cfg;
static bool         g_initialized = false;

static void check_cuda(cudaError_t err, const char* msg) {
    if (err != cudaSuccess) {
        std::cerr << "[CUDA ERROR] " << msg << ": "
                  << cudaGetErrorString(err) << std::endl;
        throw std::runtime_error("CUDA call failed");
    }
}

void init_verify_engine(const VerifyConfig& cfg) {
    if (g_initialized) {
        return;
    }
    g_cfg = cfg;

    int device = 0;
    cudaDeviceProp prop{};
    if (cudaGetDevice(&device) == cudaSuccess &&
        cudaGetDeviceProperties(&prop, device) == cudaSuccess) {
        std::cout << "[GPU] Using device " << device << ": "
                  << prop.name << std::endl;
    } else {
        std::cout << "[GPU] Unable to query CUDA device properties." << std::endl;
    }

    g_initialized = true;
}

void shutdown_verify_engine() {
    if (!g_initialized) return;
    cudaDeviceSynchronize();
    g_initialized = false;
}

void verify_tokens(
    const float* logits,
    std::size_t  batch_size,
    std::size_t  vocab_size,
    int*         accepted
) {
    if (!g_initialized) {
        VerifyConfig default_cfg;
        default_cfg.max_tokens = static_cast<int>(batch_size);
        init_verify_engine(default_cfg);
    }

    std::size_t logits_bytes   = batch_size * vocab_size * sizeof(float);
    std::size_t accepted_bytes = batch_size * sizeof(int);

    float* d_logits   = nullptr;
    int*   d_accepted = nullptr;

    check_cuda(cudaMalloc(&d_logits, logits_bytes),   "cudaMalloc d_logits");
    check_cuda(cudaMalloc(&d_accepted, accepted_bytes), "cudaMalloc d_accepted");

    check_cuda(cudaMemcpy(d_logits, logits, logits_bytes, cudaMemcpyHostToDevice),
               "cudaMemcpy H2D logits");

    launch_verify_kernel(d_logits, batch_size, vocab_size, d_accepted, 0);

    check_cuda(cudaDeviceSynchronize(), "cudaDeviceSynchronize");

    check_cuda(cudaMemcpy(accepted, d_accepted, accepted_bytes, cudaMemcpyDeviceToHost),
               "cudaMemcpy D2H accepted");

    cudaFree(d_logits);
    cudaFree(d_accepted);
}

// -----------------------------------------------------------------------------
// A tiny test main() so that `make test` actually runs something.
// In real integration you will link libdfvg_gpu.so from another program.
// -----------------------------------------------------------------------------
int main() {
    std::cout << "[TEST] Running DFVG GPU verify engine smoke test..." << std::endl;

    const std::size_t batch_size  = 4;
    const std::size_t vocab_size  = 8;

    // Construct a tiny logits matrix on CPU.
    std::vector<float> logits(batch_size * vocab_size, -1.0f);
    // Make sample 0 clearly "good"
    logits[0 * vocab_size + 3] = 2.0f;
    // Sample 1: all negative -> likely rejected
    // Sample 2: one positive
    logits[2 * vocab_size + 5] = 1.5f;
    // Sample 3: all zeros
    for (std::size_t j = 0; j < vocab_size; ++j) {
        logits[3 * vocab_size + j] = 0.0f;
    }

    std::vector<int> accepted(batch_size, 0);

    VerifyConfig cfg;
    cfg.max_tokens = static_cast<int>(batch_size);
    init_verify_engine(cfg);

    verify_tokens(logits.data(), batch_size, vocab_size, accepted.data());

    shutdown_verify_engine();

    std::cout << "[TEST] Accepted results: ";
    for (std::size_t i = 0; i < batch_size; ++i) {
        std::cout << accepted[i] << " ";
    }
    std::cout << std::endl;

    std::cout << "[TEST] Done." << std::endl;
    return 0;
}
