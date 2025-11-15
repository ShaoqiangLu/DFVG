#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Utility script to download all draft/verify models used in DFVG experiments.

Usage examples:
    # Download all models
    python scripts/download_models.py --model all

    # Download a single model
    python scripts/download_models.py --model llama-7b

    # Download multiple models
    python scripts/download_models.py --model llama-7b vicuna-7b qwen3-8b
"""

import argparse
import sys
from pathlib import Path

try:
    from huggingface_hub import snapshot_download
except ImportError:
    print(
        "[ERROR] huggingface_hub is not installed.\n"
        "        Please run: pip install huggingface_hub\n"
    )
    sys.exit(1)


# Mapping from local alias (used in configs/*.yaml) to remote repositories.
# NOTE: You MUST replace the `repo_id` fields with the actual model repositories you use.
MODEL_SPECS = {
    # ----- Verify models -----
    "llama-7b": {
        "repo_id": "YOUR_ORG/YOUR_LLAMA_7B_REPO",  # TODO: replace with the real repo id
        "revision": "main",
        "description": "Verify model: LLaMA-7B",
    },
    "vicuna-7b": {
        "repo_id": "YOUR_ORG/YOUR_VICUNA_7B_REPO",  # e.g., lmsys/vicuna-7b-v1.5
        "revision": "main",
        "description": "Verify model: Vicuna-7B",
    },
    "opt-13b": {
        "repo_id": "YOUR_ORG/YOUR_OPT_13B_REPO",  # e.g., facebook/opt-13b
        "revision": "main",
        "description": "Verify model: OPT-13B",
    },
    "qwen3-8b": {
        "repo_id": "YOUR_ORG/YOUR_QWEN3_8B_REPO",  # e.g., Qwen/Qwen2.5-7B or your internal fork
        "revision": "main",
        "description": "Verify model: Qwen3-8B",
    },

    # ----- Draft models -----
    "vicuna-160m": {
        "repo_id": "YOUR_ORG/YOUR_VICUNA_160M_REPO",
        "revision": "main",
        "description": "Draft model: Vicuna-160M",
    },
    "llama-160m": {
        "repo_id": "YOUR_ORG/YOUR_LLAMA_160M_REPO",
        "revision": "main",
        "description": "Draft model: LLaMA-160M",
    },
    "opt-125m": {
        "repo_id": "YOUR_ORG/YOUR_OPT_125M_REPO",  # e.g., facebook/opt-125m
        "revision": "main",
        "description": "Draft model: OPT-125M",
    },
    "qwen3-0.6b": {
        "repo_id": "YOUR_ORG/YOUR_QWEN3_0_6B_REPO",
        "revision": "main",
        "description": "Draft model: Qwen3-0.6B",
    },
}


def download_single_model(alias: str, output_dir: Path, use_symlinks: bool = False) -> None:
    """
    Download a single model identified by its alias into `output_dir/alias`.

    Parameters
    ----------
    alias : str
        Local model alias, e.g., "llama-7b".
    output_dir : Path
        Root directory for storing all models.
    use_symlinks : bool
        Whether to let huggingface_hub use symlinks to its cache directory.
        Set to False if you want a fully self-contained copy.
    """
    if alias not in MODEL_SPECS:
        print(f"[ERROR] Unknown model alias: {alias}")
        return

    spec = MODEL_SPECS[alias]
    repo_id = spec["repo_id"]
    revision = spec.get("revision", "main")

    if "YOUR_ORG/" in repo_id or "YOUR_" in repo_id:
        print(
            f"[WARNING] Model `{alias}` still has a placeholder repo_id: {repo_id}\n"
            "          Please edit scripts/download_models.py and set it to a real repository.\n"
        )
        return

    target_dir = output_dir / alias
    target_dir.mkdir(parents=True, exist_ok=True)

    print(f"[INFO] Downloading {alias}: {spec.get('description', '')}")
    print(f"[INFO]   Repo:     {repo_id}")
    print(f"[INFO]   Revision: {revision}")
    print(f"[INFO]   Local:    {target_dir}")

    snapshot_download(
        repo_id=repo_id,
        revision=revision,
        local_dir=str(target_dir),
        local_dir_use_symlinks=use_symlinks,
    )

    print(f"[OK] Finished downloading `{alias}`.\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download draft/verify models used in DFVG experiments."
    )
    parser.add_argument(
        "--model",
        "-m",
        nargs="+",
        required=True,
        help=(
            "Model alias(es) to download. "
            "Use one or more of: "
            f"{', '.join(sorted(MODEL_SPECS.keys()))}, or 'all'."
        ),
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        type=str,
        default="models",
        help="Root directory where models will be stored (default: ./models).",
    )
    parser.add_argument(
        "--no-symlinks",
        action="store_true",
        help="Disable symlinks and create a fully materialized copy of each model.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    output_dir = Path(args.output_dir).expanduser().resolve()
    use_symlinks = not args.no_symlinks

    if "all" in args.model:
        aliases = sorted(MODEL_SPECS.keys())
    else:
        aliases = args.model

    print(f"[INFO] Models to download: {', '.join(aliases)}")
    print(f"[INFO] Output directory:   {output_dir}\n")

    for alias in aliases:
        download_single_model(alias, output_dir=output_dir, use_symlinks=use_symlinks)


if __name__ == "__main__":
    main()

