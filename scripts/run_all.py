#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
run_all.py

High-level launcher for DFVG experiments.

This script:
  - Locates DFVG root and cpu/cpu_main.py
  - Runs cpu_main.py with given arguments
  - Optionally repeats the run multiple times
  - Captures logs into results/run_all-<timestamp>/
  - Parses "Throughput: XX tokens/s" from cpu_main.py output
"""

import argparse
import subprocess
import sys
import re
import json
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Optional


# ============================================================
# Path helpers
# ============================================================

THIS_DIR = Path(__file__).resolve().parent
DFVG_ROOT = THIS_DIR.parent          # DFVG/
CPU_MAIN = DFVG_ROOT / "cpu" / "cpu_main.py"
RESULTS_DIR = DFVG_ROOT / "results"


# ============================================================
# Run a single cpu_main.py process
# ============================================================

def run_single(
    model_path: str,
    dataset_path: str,
    max_new_tokens: int,
    draft_length: int,
    batch_size: int,
    fpga_device_id: int,
    gpu_device_id: int,
    log_dir: Path,
    run_id: int
) -> Tuple[float, Path]:
    """
    Run one DFVG experiment via cpu_main.py.

    Returns:
        (throughput_tokens_per_sec, log_path)
    """
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"run_{run_id:03d}.log"
    err_path = log_dir / f"run_{run_id:03d}.err"

    cmd: List[str] = [
        sys.executable,
        str(CPU_MAIN),
        "--model-path", model_path,
        "--dataset-path", dataset_path,
        "--max-new-tokens", str(max_new_tokens),
        "--draft-length", str(draft_length),
        "--batch-size", str(batch_size),
        "--fpga-device-id", str(fpga_device_id),
        "--gpu-device-id", str(gpu_device_id),
    ]

    print("=" * 80)
    print(f"[run_all] Run #{run_id}:")
    print("[run_all] Command:", " ".join(cmd))
    print("=" * 80)

    proc = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    # Write logs to files
    log_path.write_text(proc.stdout, encoding="utf-8")
    err_path.write_text(proc.stderr, encoding="utf-8")

    if proc.returncode != 0:
        print(f"[run_all] WARNING: run #{run_id} exited with code {proc.returncode}")
        print(f"[run_all] See logs:\n  stdout: {log_path}\n  stderr: {err_path}")

    # Parse throughput from stdout: "Throughput:        123.45 tokens/s"
    throughput = parse_throughput(proc.stdout)
    if throughput is None:
        print(f"[run_all] WARNING: failed to parse throughput from run #{run_id} log.")
    else:
        print(f"[run_all] Run #{run_id} throughput: {throughput:.2f} tokens/s")

    return throughput or 0.0, log_path


def parse_throughput(stdout_text: str) -> Optional[float]:
    """Extract 'Throughput: X tokens/s' from cpu_main.py stdout."""
    pattern = re.compile(r"Throughput:\s*([0-9.]+)\s+tokens/s")
    match = pattern.search(stdout_text)
    if not match:
        return None
    try:
        return float(match.group(1))
    except ValueError:
        return None


# ============================================================
# Main CLI
# ============================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="DFVG end-to-end experiment launcher"
    )
    parser.add_argument(
        "--model-path",
        type=str,
        required=True,
        help="Path to model weights/config (passed to cpu_main.py).",
    )
    parser.add_argument(
        "--dataset-path",
        type=str,
        required=True,
        help="Path to dataset or prompt file (passed to cpu_main.py).",
    )
    parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=128,
        help="Max number of new tokens to generate.",
    )
    parser.add_argument(
        "--draft-length",
        type=int,
        default=8,
        help="Draft length used by FPGA (draft-on-FPGA).",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1,
        help="Batch size for cpu_main.py.",
    )
    parser.add_argument(
        "--fpga-device-id",
        type=int,
        default=0,
        help="FPGA device index (passed to cpu_main.py).",
    )
    parser.add_argument(
        "--gpu-device-id",
        type=int,
        default=0,
        help="GPU device index (passed to cpu_main.py).",
    )
    parser.add_argument(
        "--num-runs",
        type=int,
        default=1,
        help="Number of repeated runs for averaging.",
    )
    parser.add_argument(
        "--tag",
        type=str,
        default="",
        help="Optional tag string appended to the result folder name.",
    )
    parser.add_argument(
        "--print-summary-only",
        action="store_true",
        help="Print only the summary line at the end (suppress per-run logs).",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if not CPU_MAIN.exists():
        print(f"[run_all] ERROR: cpu_main.py not found at {CPU_MAIN}")
        sys.exit(1)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    folder_name = f"run_all-{timestamp}"
    if args.tag:
        folder_name += f"-{args.tag}"
    out_dir = RESULTS_DIR / folder_name
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"[run_all] DFVG root:    {DFVG_ROOT}")
    print(f"[run_all] cpu_main.py:  {CPU_MAIN}")
    print(f"[run_all] results dir:  {out_dir}")
    print(f"[run_all] num_runs:     {args.num_runs}")
    print("-" * 80)

    throughputs: List[float] = []
    log_paths: List[Path] = []

    for run_id in range(1, args.num_runs + 1):
        thr, log_path = run_single(
            model_path=args.model_path,
            dataset_path=args.dataset_path,
            max_new_tokens=args.max_new_tokens,
            draft_length=args.draft_length,
            batch_size=args.batch_size,
            fpga_device_id=args.fpga_device_id,
            gpu_device_id=args.gpu_device_id,
            log_dir=out_dir,
            run_id=run_id,
        )
        throughputs.append(thr)
        log_paths.append(log_path)

    # Summary
    valid = [t for t in throughputs if t > 0]
    avg_thr = sum(valid) / len(valid) if valid else 0.0

    summary = {
        "model_path": args.model_path,
        "dataset_path": args.dataset_path,
        "max_new_tokens": args.max_new_tokens,
        "draft_length": args.draft_length,
        "batch_size": args.batch_size,
        "fpga_device_id": args.fpga_device_id,
        "gpu_device_id": args.gpu_device_id,
        "num_runs": args.num_runs,
        "throughputs": throughputs,
        "throughput_avg": avg_thr,
        "log_dir": str(out_dir),
    }

    # Save summary.json
    summary_path = out_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print("=" * 80)
    print(f"[run_all] Throughputs (tokens/s): {throughputs}")
    print(f"[run_all] Average throughput:     {avg_thr:.2f} tokens/s")
    print(f"[run_all] Summary written to:     {summary_path}")
    print("=" * 80)


if __name__ == "__main__":
    main()
