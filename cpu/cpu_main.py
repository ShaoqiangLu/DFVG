#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cpu_main.py

Host-side runtime & orchestration for DFVG:
- Load model & dataset metadata
- Coordinate FPGA draft generation
- Launch GPU verification
- Maintain token sequences and final outputs
- Measure end-to-end throughput (tokens/s)

This file is intentionally "framework-like":
you only need to replace the hardware-specific stubs
in FPGAInterface and GPUVerifier with real calls.
"""

import argparse
import time
from dataclasses import dataclass, field
from typing import List, Dict, Any, Tuple, Optional
import logging
import random

# ============================================================
# Logging & basic config
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s][%(levelname)s] %(message)s"
)
logger = logging.getLogger("DFVG-CPU")


# ============================================================
# Config definitions
# ============================================================

@dataclass
class DFVGConfig:
    model_path: str
    dataset_path: str
    max_new_tokens: int = 128
    draft_length: int = 8            # how many tokens FPGA drafts each step
    batch_size: int = 1              # 单 batch 推理（可以以后扩）
    fpga_device_id: int = 0
    gpu_device_id: int = 0
    eos_token_id: int = 2            # 按你实际模型改
    pad_token_id: int = 0
    log_interval: int = 10           # 每多少个 step 打一次 log
    # 下面预留一些你后面可能用的配置
    fpga_slot_count: int = 1         # 多 slot 并行时再扩展
    gpu_streams: int = 1


# ============================================================
# Token sequence state on CPU
# ============================================================

@dataclass
class SequenceState:
    """Track one sequence's current state on CPU."""
    input_ids: List[int]                 # 初始 prompt
    generated_ids: List[int] = field(default_factory=list)
    is_finished: bool = False

    @property
    def total_length(self) -> int:
        return len(self.input_ids) + len(self.generated_ids)

    @property
    def context(self) -> List[int]:
        """Current prefix (input + generated)."""
        return self.input_ids + self.generated_ids

    @property
    def new_token_count(self) -> int:
        return len(self.generated_ids)


# ============================================================
# FPGA / GPU interfaces (to be wired with real HW)
# ============================================================

class FPGAInterface:
    """
    Abstraction for FPGA draft generator.

    In real implementation, this class should:
    - Initialize PCIe/XDMA
    - Manage DMA buffers
    - Dispatch prefix tokens to FPGA
    - Receive draft sequences
    """

    def __init__(self, device_id: int, config: DFVGConfig):
        self.device_id = device_id
        self.config = config
        self._init_device()

    def _init_device(self):
        logger.info(f"[FPGA] Initializing FPGA device #{self.device_id} ...")
        # TODO: load FPGA driver / open XDMA / mmap buffers
        # For now we just simulate
        time.sleep(0.05)
        logger.info("[FPGA] Initialization done.")

    def generate_draft(
        self,
        prefix_tokens: List[int],
        draft_length: int
    ) -> List[int]:
        """
        Given current prefix, ask FPGA to generate a draft of length L.

        Real flow:
        - Copy prefix to FPGA input buffer
        - Trigger hardware kernel
        - Wait for completion (or poll)
        - Read back draft tokens

        Here we just mock with random tokens.
        """
        # TODO: replace with real HW call
        # Simulate hardware latency
        time.sleep(0.001)  # pretend FPGA is very fast
        draft = [random.randint(3, 30000) for _ in range(draft_length)]
        return draft


class GPUVerifier:
    """
    Abstraction for GPU verification kernel.

    In real implementation, this class should:
    - Initialize CUDA context
    - Load model weights (or attach to vLLM / TRT engine)
    - Provide verify_draft() which:
        * runs full model forward
        * compares draft tokens with model predictions
        * returns how many tokens are accepted & whether eos is hit
    """

    def __init__(self, device_id: int, config: DFVGConfig):
        self.device_id = device_id
        self.config = config
        self._init_device()

    def _init_device(self):
        logger.info(f"[GPU] Initializing GPU device #{self.device_id} ...")
        # TODO: set CUDA_VISIBLE_DEVICES / init PyTorch / CUDA driver
        time.sleep(0.05)
        logger.info("[GPU] Initialization done.")

    def verify_draft(
        self,
        prefix_tokens: List[int],
        draft_tokens: List[int]
    ) -> Tuple[int, bool]:
        """
        Verify FPGA draft on GPU.

        Return:
            accepted_len: number of tokens in draft that are accepted
            eos_hit: whether EOS token encountered within accepted part

        Real implementation:
        - Run model(prefix)
        - Compute logits for next positions
        - Compare argmax (or sampling distribution) with draft_tokens
        - Count prefix of matching tokens (accepted prefix)
        """
        # TODO: replace with真实 GPU kernel调用

        # Mock behavior:
        # - Randomly accept 1 ~ len(draft_tokens) tokens
        # - Randomly decide eos
        if not draft_tokens:
            return 0, False

        # 模拟模型“还挺靠谱”的场景：大概率接受较多 token
        max_accept = len(draft_tokens)
        accepted_len = random.randint(max(1, max_accept // 2), max_accept)

        # 模拟 eos: 小概率触发
        eos_hit = random.random() < 0.05

        # 模拟 GPU latency
        time.sleep(0.002)

        return accepted_len, eos_hit


# ============================================================
# Dataset loader (very simple placeholder)
# ============================================================

def load_dataset(dataset_path: str, batch_size: int) -> List[List[int]]:
    """
    Load or construct prompts from dataset.

    For now we just simulate a few short prompts.
    You can replace this with:
    - loading from jsonl
    - encoding with tokenizer
    """
    logger.info(f"[DATA] Loading dataset from {dataset_path} ...")

    # TODO: replace with真实数据加载
    # 比如：读 json / txt / token ids
    prompts = [
        [1, 10, 11, 12],
        [1, 23, 24],
        [1, 99, 100, 101, 102],
    ]

    # 只取前 batch_size 条，保持简单
    prompts = prompts[:batch_size]

    logger.info(f"[DATA] Loaded {len(prompts)} prompts.")
    return prompts


# ============================================================
# DFVG Orchestrator
# ============================================================

class DFVGOrchestrator:
    """
    CPU-side orchestrator for DFVG.
    Manages:
    - sequence states
    - FPGA / GPU calls
    - end-to-end token throughput measurement
    """

    def __init__(self, config: DFVGConfig):
        self.config = config
        self.fpga = FPGAInterface(config.fpga_device_id, config)
        self.gpu = GPUVerifier(config.gpu_device_id, config)

    def run_batch(self, prompts: List[List[int]]):
        """Run DFVG on a batch of prompts, measure end-to-end tokens/s."""
        sequences = [SequenceState(input_ids=p) for p in prompts]

        start_time = time.perf_counter()

        step = 0
        while True:
            # Check if all sequences finished
            if all(seq.is_finished for seq in sequences):
                break

            step += 1
            if step % self.config.log_interval == 0:
                logger.info(f"[CPU] Step {step} ...")

            for seq in sequences:
                if seq.is_finished:
                    continue

                # 1) FPGA draft
                prefix = seq.context
                draft_tokens = self.fpga.generate_draft(
                    prefix_tokens=prefix,
                    draft_length=self.config.draft_length,
                )

                # 2) GPU verify
                accepted_len, eos_hit = self.gpu.verify_draft(
                    prefix_tokens=prefix,
                    draft_tokens=draft_tokens,
                )

                # 3) CPU commit accepted tokens
                accepted_tokens = draft_tokens[:accepted_len]
                seq.generated_ids.extend(accepted_tokens)

                # 4) Check stopping conditions
                if eos_hit or seq.new_token_count >= self.config.max_new_tokens:
                    seq.is_finished = True

            # Optional: 简单的防御性 break，避免死循环
            if step > self.config.max_new_tokens * 2:
                logger.warning("[CPU] Step exceeded safe limit, breaking.")
                break

        end_time = time.perf_counter()
        elapsed = end_time - start_time

        total_new_tokens = sum(seq.new_token_count for seq in sequences)
        tokens_per_sec = total_new_tokens / elapsed if elapsed > 0 else 0.0

        logger.info("========== DFVG Run Summary ==========")
        logger.info(f"Batch size:        {len(sequences)}")
        logger.info(f"Max new tokens:    {self.config.max_new_tokens}")
        logger.info(f"Draft length:      {self.config.draft_length}")
        logger.info(f"Total new tokens:  {total_new_tokens}")
        logger.info(f"Total time (s):    {elapsed:.4f}")
        logger.info(f"Throughput:        {tokens_per_sec:.2f} tokens/s")
        logger.info("======================================")

        # 返回结果，方便上层脚本写入文件 / 做统计
        return {
            "sequences": sequences,
            "total_new_tokens": total_new_tokens,
            "elapsed": elapsed,
            "tokens_per_sec": tokens_per_sec,
        }


# ============================================================
# CLI
# ============================================================

def parse_args() -> DFVGConfig:
    parser = argparse.ArgumentParser(description="DFVG CPU Orchestrator")
    parser.add_argument("--model-path", type=str, required=True,
                        help="Path to model weights / config.")
    parser.add_argument("--dataset-path", type=str, required=True,
                        help="Path to dataset or prompt file.")
    parser.add_argument("--max-new-tokens", type=int, default=128)
    parser.add_argument("--draft-length", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--fpga-device-id", type=int, default=0)
    parser.add_argument("--gpu-device-id", type=int, default=0)
    parser.add_argument("--eos-token-id", type=int, default=2)
    parser.add_argument("--pad-token-id", type=int, default=0)
    parser.add_argument("--log-interval", type=int, default=10)

    args = parser.parse_args()

    cfg = DFVGConfig(
        model_path=args.model_path,
        dataset_path=args.dataset_path,
        max_new_tokens=args.max_new_tokens,
        draft_length=args.draft_length,
        batch_size=args.batch_size,
        fpga_device_id=args.fpga_device_id,
        gpu_device_id=args.gpu_device_id,
        eos_token_id=args.eos_token_id,
        pad_token_id=args.pad_token_id,
        log_interval=args.log_interval,
    )
    return cfg


def main():
    config = parse_args()
    logger.info("========== DFVG CPU Runtime ==========")
    logger.info(f"Model path:   {config.model_path}")
    logger.info(f"Dataset path: {config.dataset_path}")
    logger.info(f"Max new tokens: {config.max_new_tokens}")
    logger.info(f"Draft length:   {config.draft_length}")
    logger.info("======================================")

    # 1) Load dataset
    prompts = load_dataset(config.dataset_path, config.batch_size)

    # 2) Run DFVG orchestrator
    orchestrator = DFVGOrchestrator(config)
    results = orchestrator.run_batch(prompts)

    # 3) 简单打印一下生成结果（以后可以写入文件）
    for i, seq in enumerate(results["sequences"]):
        logger.info(f"[SEQ {i}] input_ids = {seq.input_ids}")
        logger.info(f"[SEQ {i}] generated_ids (len={len(seq.generated_ids)}):")
        logger.info(f"{seq.generated_ids}")


if __name__ == "__main__":
    main()
