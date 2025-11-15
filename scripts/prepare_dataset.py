#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Prepare dataset for DFVG / LLM inference experiments.

This script reads a custom dataset file (JSON / JSONL) and converts it into
a normalized JSONL format suitable for benchmarking speculative decoding.

Example usages
--------------
# Basic usage: convert custom_data.json -> data/processed/custom_data.jsonl
python scripts/prepare_dataset.py \
    --input custom_data.json

# Limit to 1,000 samples and shuffle them
python scripts/prepare_dataset.py \
    --input custom_data.json \
    --max-samples 1000 \
    --shuffle

# Specify output path explicitly
python scripts/prepare_dataset.py \
    --input custom_data.json \
    --output data/processed/my_dataset.jsonl
"""

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Union


# Canonical keys we want to generate per sample
CANONICAL_FIELDS = ["id", "prompt", "reference", "max_new_tokens"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Normalize a custom dataset into a standard JSONL format."
    )
    parser.add_argument(
        "--input",
        "-i",
        required=True,
        type=str,
        help="Path to the input dataset file (JSON or JSONL).",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default="",
        help=(
            "Path to the output JSONL file. "
            "If not set, will default to data/processed/<input_stem>.jsonl"
        ),
    )
    parser.add_argument(
        "--max-samples",
        type=int,
        default=None,
        help="Optional upper bound on the number of samples to keep.",
    )
    parser.add_argument(
        "--shuffle",
        action="store_true",
        help="Shuffle samples before truncating / writing.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed used when --shuffle is enabled (default: 42).",
    )
    parser.add_argument(
        "--max-prompt-length",
        type=int,
        default=None,
        help=(
            "If set, discard samples whose prompt length (characters) "
            "exceeds this value."
        ),
    )
    parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=128,
        help="Default max_new_tokens field for each sample (default: 128).",
    )
    return parser.parse_args()


def read_json_or_jsonl(path: Path) -> List[Any]:
    """
    Read a JSON or JSONL file and return a list of raw objects.

    Supported formats:
    - JSONL: each non-empty line is a JSON object or a primitive.
    - JSON:
        * list[...] -> returned as a list
        * dict      -> wrapped in a list [dict]
        * anything else -> wrapped in [obj]
    """
    if not path.exists():
        print(f"[ERROR] Input file does not exist: {path}")
        sys.exit(1)

    records: List[Any] = []

    if path.suffix == ".jsonl":
        with path.open("r", encoding="utf-8") as f:
            for line_no, line in enumerate(f, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError as e:
                    print(
                        f"[WARN] Failed to parse JSONL line {line_no} in {path}: {e}"
                    )
                    continue
                records.append(obj)
    else:
        with path.open("r", encoding="utf-8") as f:
            try:
                obj = json.load(f)
            except json.JSONDecodeError as e:
                print(f"[ERROR] Failed to parse JSON from {path}: {e}")
                sys.exit(1)

        if isinstance(obj, list):
            records = obj
        else:
            # For dict / primitive / string etc., wrap it as a single record
            records = [obj]

    if not records:
        print(f"[WARN] No records found in {path}")

    return records


def _get_first_present(d: Dict[str, Any], keys: Iterable[str]) -> Optional[Any]:
    for k in keys:
        if k in d and d[k] is not None:
            return d[k]
    return None


def normalize_sample(
    raw: Union[Dict[str, Any], str],
    idx: int,
    default_max_new_tokens: int,
    id_prefix: str,
) -> Optional[Dict[str, Any]]:
    """
    Normalize a raw item into our canonical sample format:

    {
      "id": "custom-000001",
      "prompt": "...",
      "reference": "...",
      "max_new_tokens": 128
    }

    - If `raw` is a string, it is treated as a prompt.
    - If `raw` is a dict, we try multiple common fields:
        * prompt: "prompt", "input", "question", "instruction"
        * reference: "reference", "answer", "output", "response", "target"
    """
    sample: Dict[str, Any] = {}

    sample_id = f"{id_prefix}-{idx:06d}"
    sample["id"] = sample_id

    if isinstance(raw, str):
        prompt = raw
        reference = ""
    elif isinstance(raw, dict):
        prompt = _get_first_present(
            raw,
            ["prompt", "input", "question", "instruction", "query", "src"],
        )
        reference = _get_first_present(
            raw,
            ["reference", "answer", "output", "response", "target", "tgt"],
        )
    else:
        # Unsupported type
        return None

    if not prompt:
        # Sample without prompt is not usable
        return None

    if reference is None:
        reference = ""

    sample["prompt"] = str(prompt)
    sample["reference"] = str(reference)
    sample["max_new_tokens"] = int(default_max_new_tokens)

    return sample


def filter_by_prompt_length(
    samples: List[Dict[str, Any]], max_len: Optional[int]
) -> List[Dict[str, Any]]:
    if max_len is None:
        return samples

    filtered: List[Dict[str, Any]] = []
    for s in samples:
        if len(s["prompt"]) <= max_len:
            filtered.append(s)
    dropped = len(samples) - len(filtered)
    if dropped > 0:
        print(
            f"[INFO] Dropped {dropped} sample(s) whose prompt length "
            f"exceeds {max_len} characters."
        )
    return filtered


def write_jsonl(samples: List[Dict[str, Any]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as f:
        for s in samples:
            # Only keep canonical fields, in a stable order
            obj = {k: s.get(k, "") for k in CANONICAL_FIELDS}
            line = json.dumps(obj, ensure_ascii=False)
            f.write(line + "\n")

    print(f"[OK] Wrote {len(samples)} sample(s) to {output_path}")


def main() -> None:
    args = parse_args()

    input_path = Path(args.input).expanduser().resolve()

    if args.output:
        output_path = Path(args.output).expanduser().resolve()
    else:
        # Default output path: data/processed/<input_stem>.jsonl
        out_dir = Path("data/processed")
        output_path = out_dir / f"{input_path.stem}.jsonl"

    print(f"[INFO] Reading input dataset from {input_path}")
    raw_records = read_json_or_jsonl(input_path)

    # Normalize all records
    samples: List[Dict[str, Any]] = []
    id_prefix = input_path.stem

    for idx, raw in enumerate(raw_records):
        sample = normalize_sample(
            raw=raw,
            idx=idx,
            default_max_new_tokens=args.max_new_tokens,
            id_prefix=id_prefix,
        )
        if sample is None:
            continue
        samples.append(sample)

    if not samples:
        print("[ERROR] No valid samples found after normalization.")
        sys.exit(1)

    print(f"[INFO] Loaded {len(samples)} normalized sample(s).")

    # Filter by prompt length if requested
    samples = filter_by_prompt_length(samples, args.max_prompt_length)

    # Shuffle if requested
    if args.shuffle:
        random.seed(args.seed)
        random.shuffle(samples)
        print(f"[INFO] Shuffled samples with seed={args.seed}.")

    # Truncate if requested
    if args.max_samples is not None and args.max_samples > 0:
        if len(samples) > args.max_samples:
            print(
                f"[INFO] Truncating samples from {len(samples)} "
                f"to {args.max_samples}."
            )
            samples = samples[: args.max_samples]

    # Final sanity check
    if not samples:
        print("[ERROR] No samples left after filtering / truncation.")
        sys.exit(1)

    # Write output
    write_jsonl(samples, output_path)


if __name__ == "__main__":
    main()
