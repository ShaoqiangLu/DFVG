// gpu/include/verify_engine.h
#pragma once

#include <cstddef>

// Simple configuration for the verify engine.
// You can extend this later (e.g., streams, block sizes, etc.).
struct VerifyConfig {
    int max_tokens = 0;
};

// Initialize GPU verify engine (allocate buffers, warm-up, etc.)
void init_verify_engine(const VerifyConfig& cfg);

// Release all GPU resources.
void shutdown_verify_engine();

// A toy verify function:
//   logits:  [batch_size, vocab_size] flattened row-major
//   accepted: output buffer of length batch_size; 1 = accepted, 0 = rejected
//
// In a real system this would compare draft tokens vs. logits;
// here we just implement a simple condition as a placeholder.
void verify_tokens(
    const float* logits,
    std::size_t  batch_size,
    std::size_t  vocab_size,
    int*         accepted
);
