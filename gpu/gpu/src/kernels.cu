// gpu/src/kernels.cu
#include <cuda_runtime.h>
#include <cmath>
#include <cstdio>

// A simple kernel: for each batch item, check if the max logit exceeds a
// threshold; if so, mark accepted[i] = 1, otherwise 0.
// This mimics a "verification" step in a very simplified way.
__global__ void verify_kernel(
    const float* __restrict__ logits,
    std::size_t               batch_size,
    std::size_t               vocab_size,
    int* __restrict__         accepted,
    float                     threshold
) {
    std::size_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= batch_size) return;

    const float* row = logits + idx * vocab_size;

    float max_val = row[0];
    for (std::size_t j = 1; j < vocab_size; ++j) {
        float v = row[j];
        if (v > max_val) {
            max_val = v;
        }
    }

    accepted[idx] = (max_val > threshold) ? 1 : 0;
}

// A small helper for launching the kernel from host code.
void launch_verify_kernel(
    const float* d_logits,
    std::size_t  batch_size,
    std::size_t  vocab_size,
    int*         d_accepted,
    cudaStream_t stream = 0
) {
    const int threads_per_block = 128;
    int blocks = static_cast<int>((batch_size + threads_per_block - 1) / threads_per_block);

    const float threshold = 0.0f;  // toy threshold

    verify_kernel<<<blocks, threads_per_block, 0, stream>>>(
        d_logits,
        batch_size,
        vocab_size,
        d_accepted,
        threshold
    );
}
