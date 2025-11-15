#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Add a new (draft, verify) model pair entry into draft_params.yaml.

Example:
    python scripts/add_model.py \
        --target llama-7b \
        --draft llama-160m

This will append a pair like:

  - name: "llama_7b_with_llama_160m"
    draft_config: "configs/llama-160m.yaml"
    verify_config: "configs/llama-7b.yaml"
    max_draft_tokens: 32
    max_verify_tokens: 16
    acceptance_ratio_threshold: 0.65
    notes: "Auto-added pair: llama-7b (verify) with llama-160m (draft)."
"""

import argparse
import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print(
        "[ERROR] PyYAML is not installed.\n"
        "        Please run: pip install pyyaml\n"
    )
    sys.exit(1)


DEFAULT_CONFIG_PATH = Path("draft_params.yaml")


def to_safe_name(target: str, draft: str) -> str:
    """
    Generate a safe pair name from target and draft model aliases.

    Example:
        target = "llama-7b", draft = "llama-160m"
        => "llama_7b_with_llama_160m"
    """
    def normalize(s: str) -> str:
        # Replace non-alphanumeric characters with underscores
        s = re.sub(r"[^0-9A-Za-z]+", "_", s)
        # Remove leading/trailing underscores
        s = s.strip("_")
        return s

    return f"{normalize(target)}_with_{normalize(draft)}"


def load_config(path: Path) -> dict:
    """
    Load draft_params.yaml. If it does not exist, create a minimal skeleton.
    """
    if not path.exists():
        print(f"[WARN] Config file not found, creating a new one at {path}")
        cfg = {
            "defaults": {
                "max_draft_tokens": 64,
                "min_draft_tokens": 8,
                "max_verify_tokens": 16,
                "acceptance_ratio_threshold": 0.6,
                "backoff_ratio": 0.5,
                "growth_ratio": 1.2,
                "max_pending_tokens": 256,
                "enable_adaptive_drafting": True,
                "enable_latency_aware_scheduling": True,
            },
            "pairs": [],
            "ablation": {
                "disable_speculative_decoding": {
                    "enabled": False,
                },
                "fixed_draft_length": {
                    "enabled": False,
                    "value": 32,
                },
                "single_pair_only": {
                    "enabled": False,
                    "pair_name": "",
                },
            },
        }
        return cfg

    with path.open("r", encoding="utf-8") as f:
        try:
            cfg = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"[ERROR] Failed to parse YAML from {path}: {e}")
            sys.exit(1)

    if cfg is None:
        cfg = {}

    cfg.setdefault("defaults", {})
    cfg.setdefault("pairs", [])
    cfg.setdefault("ablation", {})

    return cfg


def save_config(cfg: dict, path: Path) -> None:
    """
    Save the updated configuration back to YAML.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(
            cfg,
            f,
            sort_keys=False,
            default_flow_style=False,
            allow_unicode=True,
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Add a new draft/verify pair to draft_params.yaml."
    )
    parser.add_argument(
        "--target",
        required=True,
        help="Verify model alias, e.g., llama-7b, vicuna-7b, opt-13b, qwen3-8b.",
    )
    parser.add_argument(
        "--draft",
        required=True,
        help="Draft model alias, e.g., llama-160m, vicuna-160m, opt-125m, qwen3-0.6b.",
    )
    parser.add_argument(
        "--pair-name",
        help=(
            "Optional explicit pair name. "
            "If omitted, will be generated from target and draft."
        ),
    )
    parser.add_argument(
        "--config",
        type=str,
        default=str(DEFAULT_CONFIG_PATH),
        help="Path to draft_params.yaml (default: ./draft_params.yaml).",
    )
    parser.add_argument(
        "--max-draft-tokens",
        type=int,
        default=32,
        help="Max draft tokens for this pair (default: 32).",
    )
    parser.add_argument(
        "--max-verify-tokens",
        type=int,
        default=16,
        help="Max verify tokens for this pair (default: 16).",
    )
    parser.add_argument(
        "--accept-threshold",
        type=float,
        default=0.65,
        help="Acceptance ratio threshold for this pair (default: 0.65).",
    )
    parser.add_argument(
        "--notes",
        type=str,
        default="",
        help="Optional notes/comment stored with this pair.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    config_path = Path(args.config).expanduser().resolve()
    cfg = load_config(config_path)

    pairs = cfg.get("pairs", [])
    if not isinstance(pairs, list):
        print("[ERROR] `pairs` in config must be a list.")
        sys.exit(1)

    pair_name = args.pair_name or to_safe_name(args.target, args.draft)

    # Check if pair already exists
    for p in pairs:
        if p.get("name") == pair_name:
            print(f"[ERROR] Pair with name '{pair_name}' already exists in {config_path}")
            print("        You can either choose a different --pair-name or edit the file manually.")
            sys.exit(1)

    draft_config_path = f"configs/{args.draft}.yaml"
    verify_config_path = f"configs/{args.target}.yaml"

    new_pair = {
        "name": pair_name,
        "draft_config": draft_config_path,
        "verify_config": verify_config_path,
        "max_draft_tokens": args.max_draft_tokens,
        "max_verify_tokens": args.max_verify_tokens,
        "acceptance_ratio_threshold": args.accept_threshold,
        "notes": args.notes
        or f"Auto-added pair: {args.target} (verify) with {args.draft} (draft).",
    }

    pairs.append(new_pair)
    cfg["pairs"] = pairs

    save_config(cfg, config_path)

    print(f"[OK] Added new pair to {config_path}:")
    print(f"     name:        {new_pair['name']}")
    print(f"     draft:       {args.draft}  -> {draft_config_path}")
    print(f"     target:      {args.target} -> {verify_config_path}")
    print(f"     max_draft:   {args.max_draft_tokens}")
    print(f"     max_verify:  {args.max_verify_tokens}")
    print(f"     threshold:   {args.accept_threshold}")
    print(f"     notes:       {new_pair['notes']}")


if __name__ == "__main__":
    main()
