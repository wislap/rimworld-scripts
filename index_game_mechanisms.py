"""Prepare a local source generation outside the agent's execution deadline."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "N.E.K.O/plugin/plugins/neko_rimworld"))


def main():
    from mechanisms.index import build_index

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembly", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--ilspy", type=Path, default=ROOT / ".bench-data/ilspy/ilspycmd.exe")
    args = parser.parse_args()
    if args.output.exists():
        parser.error("output already exists; use a new source generation")
    with tempfile.TemporaryDirectory(prefix="neko-game-sources-") as directory:
        subprocess.run([str(args.ilspy), "--disable-updatecheck", "-p", "-o", directory, str(args.assembly)], check=True)
        result = build_index(Path(directory), args.assembly, args.output)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
