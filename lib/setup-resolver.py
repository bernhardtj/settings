#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lib"))

from settings_core import SettingsError, plan_json, resolve_lineage, setup_names, validate_setup


def main() -> int:
    parser = argparse.ArgumentParser(description="Resolve settings setup metadata.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("list")
    lineage = subparsers.add_parser("lineage")
    lineage.add_argument("setup", nargs="?", default="default")
    plan = subparsers.add_parser("plan")
    plan.add_argument("setup", nargs="?", default="default")
    validate = subparsers.add_parser("validate")
    validate.add_argument("setup", nargs="?", default="default")
    args = parser.parse_args()

    try:
        if args.command == "list":
            print("\n".join(setup_names()))
        elif args.command == "lineage":
            print(" -> ".join(resolve_lineage(args.setup)))
        elif args.command == "plan":
            print(plan_json(args.setup))
        elif args.command == "validate":
            errors = validate_setup(args.setup)
            if errors:
                for error in errors:
                    print(f"error: {error}", file=sys.stderr)
                return 1
            print(f"ok: {args.setup}")
    except SettingsError as exc:
        print(f"setup-resolver: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
