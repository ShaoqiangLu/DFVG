#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Collect experiment results from the results/ directory and aggregate them
into a single CSV file.

Assumed result formats (per file):

1) Single JSON object:
   {
     "experiment_name": "llama7b_with_llama160m_bs4",
     "pair_name": "llama7b_with_llama160m",
     "draft_model": "llama-160m",
     "verify_model": "llama-7b",
     "num_requests": 128,
     "avg_latency_ms": 45.3,
     "p95_latency_ms": 78.1,
     "throughput_tokens_per_s": 1234.5,
     "avg_acceptance_rate": 0.72,
     "max_memory_gb": 22.1,
     "notes": "baseline run"
   }

2) JSON array:
   [
     { ... record 1 ... },
     { ... record 2 ... }
   ]

3) JSONL file:
   Each line is a standalone JSON object with the same fields as above.

Any extra fields are ignored. Missing fields are kept as empty strings.
"""

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional


# Canonical columns we want in the final CSV, in order.
CANONICAL_COLUMNS = [
    "source_file",                # Path to the original result file
    "experiment_name",
    "pair_name",
    "draft_model",
    "verify_model",
    "num_requests",
    "avg_latency_ms",
    "p95_latency_ms",
    "throughput_tokens_per_s",
    "avg_acceptance_rate",
    "max_memory_gb",
    "notes",
]


def _get_first_present(d: Dict[str, Any], keys: Iterable[str]) -> Optional[Any]:
    """Return the first non-None value among the given keys in dict d."""
    for k in keys:
        if k in d and d[k] is not None:
            return d[k]
    return None


def normalize_record(raw: Dict[str, Any], source_file: Path) -> Dict[str, Any]:
    """
    Normalize a raw result record into a flat dict with canonical keys.

    This function is intentionally tolerant: it looks for multiple possible
    aliases for each field (e.g., 'throughput', 'tokens_per_s', etc.).
    """
    out: Dict[str, Any] = {}

    out["source_file"] = str(source_file)

    out["experiment_name"] = _get_first_present(
        raw,
        ["experiment_name", "exp_name", "name"],
    ) or ""

    out["pair_name"] = _get_first_present(
        raw,
        ["pair_name", "pair", "model_pair"],
    ) or ""

    out["draft_model"] = _get_first_present(
        raw,
        ["draft_model", "draft_name", "draft"],
    ) or ""

    out["verify_model"] = _get_first_present(
        raw,
        ["verify_model", "verify_name", "verify"],
    ) or ""

    out["num_requests"] = _get_first_present(
        raw,
        ["num_requests", "n_requests", "requests"],
    ) or ""

    out["avg_latency_ms"] = _get_first_present(
        raw,
        ["avg_latency_ms", "mean_latency_ms", "latency_ms"],
    ) or ""

    out["p95_latency_ms"] = _get_first_present(
        raw,
        ["p95_latency_ms", "latency_p95_ms", "p95_ms"],
    ) or ""

    out["throughput_tokens_per_s"] = _get_first_present(
        raw,
        ["throughput_tokens_per_s", "tokens_per_s", "throughput"],
    ) or ""

    out["avg_acceptance_rate"] = _get_first_present(
        raw,
        ["avg_acceptance_rate", "acceptance_rate", "mean_acceptance"],
    ) or ""

    out["max_memory_gb"] = _get_first_present(
        raw,
        ["max_memory_gb", "peak_mem_gb", "max_gpu_mem_gb"],
    ) or ""

    out["notes"] = _get_first_present(
        raw,
        ["notes", "comment", "remark"],
    ) or ""

    return out


def load_json_file(path: Path) -> List[Dict[str, Any]]:
    """
    Load a JSON or JSONL file and return a list of raw records (dicts).

    - For .json:
        - If the content is a dict -> [dict]
        - If the content is a list -> list
    - For .jsonl:
        - Each non-empty line must be a JSON object.
    """
    records: List[Dict[str, Any]] = []

    if path.suffix == ".jsonl":
        with path.open("r", encoding="utf-8") as f:
            for line_no, line in enumerate(f, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError as e:
                    print(f"[WARN] Failed to parse JSONL line {line_no} in {path}: {e}")
                    continue
                if not isinstance(obj, dict):
                    print(f"[WARN] Non-dict JSON object at {path}:{line_no}, skipping.")
                    continue
                records.append(obj)
    else:
        # .json or other extension we treat as JSON
        with path.open("r", encoding="utf-8") as f:
            try:
                obj = json.load(f)
            except json.JSONDecodeError as e:
                print(f"[WARN] Failed to parse JSON file {path}: {e}")
                return records

        if isinstance(obj, dict):
            records.append(obj)
        elif isinstance(obj, list):
            for idx, item in enumerate(obj):
                if isinstance(item, dict):
                    records.append(item)
                else:
                    print(f"[WARN] Non-dict element at index {idx} in {path}, skipping.")
        else:
            print(f"[WARN] Unsupported JSON top-level type in {path}: {type(obj)}")

    return records


def collect_results(input_dir: Path, verbose: bool = False) -> List[Dict[str, Any]]:
    """
    Walk through input_dir and collect normalized records from all JSON/JSONL files.
    """
    all_records: List[Dict[str, Any]] = []

    # We treat *.json and *.jsonl as result files.
    json_patterns = ("*.json", "*.jsonl")

    files: List[Path] = []
    for pattern in json_patterns:
        files.extend(input_dir.rglob(pattern))

    files = sorted(set(files))

    if not files:
        print(f"[WARN] No JSON/JSONL result files found under {input_dir}")
        return all_records

    if verbose:
        print(f"[INFO] Found {len(files)} result file(s) under {input_dir}")

    for path in files:
        if verbose:
            print(f"[INFO] Processing {path}")

        raw_records = load_json_file(path)
        if not raw_records:
            continue

        for raw in raw_records:
            norm = normalize_record(raw, source_file=path)
            all_records.append(norm)

    if verbose:
        print(f"[INFO] Collected {len(all_records)} record(s) in total.")

    return all_records


def write_csv(
    records: List[Dict[str, Any]],
    output_path: Path,
    columns: Iterable[str] = CANONICAL_COLUMNS,
    verbose: bool = False,
) -> None:
    """
    Write the collected records into a CSV file using the given column order.
    """
    if not records:
        print("[WARN] No records to write. CSV will not be created.")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(columns))
        writer.writeheader()
        for rec in records:
            # Ensure all keys exist
            row = {col: rec.get(col, "") for col in columns}
            writer.writerow(row)

    if verbose:
        print(f"[INFO] Wrote {len(records)} record(s) to {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect experiment results from results/ and aggregate into a CSV file."
    )
    parser.add_argument(
        "--input-dir",
        "-i",
        type=str,
        default="results",
        help="Directory containing experiment result files (default: ./results).",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default="results/summary.csv",
        help="Path to the aggregated CSV output (default: results/summary.csv).",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    input_dir = Path(args.input_dir).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    if not input_dir.exists():
        print(f"[ERROR] Input directory does not exist: {input_dir}")
        sys.exit(1)

    records = collect_results(input_dir=input_dir, verbose=args.verbose)
    if not records:
        print("[WARN] No records collected. Nothing to write.")
        sys.exit(0)

    write_csv(records, output_path=output_path, verbose=args.verbose)


if __name__ == "__main__":
    main()
