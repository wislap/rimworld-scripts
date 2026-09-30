"""Local, offline recovery capsule for the companion RimWorld repositories.

No model calls, uploads, deletion, checkout, reset, or secret configuration reads.
Git bundles preserve available history; ZIP preserves source and local evidence.
"""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

REPOS = {
    "plugin": "N.E.K.O/plugin/plugins/neko_rimworld",
    "mod": "NekoRimWorld",
    "bench": "rimworld-bench",
    "scripts": "rimworld-scripts",
    "archive": "rimworld-bench-archive",
}
CACHES = {"__pycache__", ".pytest_cache", ".ruff_cache", ".mypy_cache", "venv", ".venv"}
PYTEST_SCRATCH = re.compile(r"judge-.+(?:tests-temp-v\d+|test(?:-high)?(?:-\d{8})?-(?:\d+|final))")
SECRET = re.compile(rb"(?:(?<![A-Za-z0-9_-])sk-[A-Za-z0-9_-]{24,}|(?i:authorization)[\s\"':=]+(?i:bearer)[ ]+[A-Za-z0-9._-]{20,})")


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], stderr=subprocess.PIPE)


def digest(path):
    with Path(path).open("rb") as stream:
        return stream_digest(stream)


def stream_digest(stream):
    h = hashlib.sha256()
    while chunk := stream.read(1024 * 1024):
        h.update(chunk)
    return h.hexdigest()


def secret_check(path):
    # Gzip traces also need a decoded scan. Never print matching content.
    with path.open("rb") as probe:
        is_gzip = probe.read(2) == b"\x1f\x8b"
    opener = gzip.open if is_gzip else open
    tail = b""
    with opener(path, "rb") as stream:
        while chunk := stream.read(1024 * 1024):
            data = tail + chunk
            if SECRET.search(data):
                raise ValueError(f"Credential-shaped content detected in {path.name}; capsule not sealed")
            tail = data[-512:]


def secret_name(path):
    name = path.name.lower()
    return name == ".env" or name.startswith(".env.") or path.suffix.lower() in {".key", ".secret", ".pem"}


def inventory(root):
    files, omitted, repos = set(), [], {}
    for name, relative in REPOS.items():
        repo = root / relative
        repos[name] = {
            "path": relative,
            "head": git(repo, "rev-parse", "HEAD").decode().strip(),
            "branch": git(repo, "branch", "--show-current").decode().strip(),
            "shallow": git(repo, "rev-parse", "--is-shallow-repository").decode().strip(),
            "status": git(repo, "status", "--porcelain=v1").decode("utf-8"),
        }
        names = git(repo, "ls-files", "-z", "--cached", "--others", "--exclude-standard").split(b"\0")
        for raw in names:
            if raw:
                path = repo / raw.decode("utf-8")
                if any(part in CACHES for part in path.relative_to(repo).parts):
                    omitted.append({"path": path.relative_to(root).as_posix(), "reason": "rebuildable cache/runtime"})
                elif path.is_file() and not path.is_symlink():
                    files.add(path)
                elif path.exists():
                    omitted.append({"path": path.relative_to(root).as_posix(), "reason": "non-regular Git entry"})
    # Do not filter bin/obj here: sealed native binaries are evidence, too.
    for local in [".bench-results", ".rimworld-dev-data/Saves", "NekoRimWorld/1.6/Assemblies"]:
        for base, dirs, names in os.walk(root / local, followlinks=False):
            kept = []
            for name in dirs:
                path = Path(base) / name
                scratch = Path(base) == root / ".bench-results" and PYTEST_SCRATCH.fullmatch(name)
                if name in CACHES or scratch or path.is_symlink():
                    omitted.append({"path": path.relative_to(root).as_posix(), "reason": "rebuildable cache/runtime or symlink"})
                else:
                    kept.append(name)
            dirs[:] = kept
            for name in names:
                path = Path(base) / name
                if path.is_symlink():
                    omitted.append({"path": path.relative_to(root).as_posix(), "reason": "symlink"})
                else:
                    files.add(path)
    selected = []
    if (root / "WORKSPACE.md").is_file():
        files.add(root / "WORKSPACE.md")
    for path in sorted(files):
        relative = path.relative_to(root).as_posix()
        if secret_name(path):
            omitted.append({"path": relative, "reason": "private configuration/key filename"})
        else:
            selected.append(path)
    return selected, repos, omitted


def write_json(path, value):
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def seal(root, out):
    if out.exists():
        raise ValueError("Output must be a new directory; existing capsules are never overwritten")
    out.mkdir(parents=True)
    files, repos, omitted = inventory(root)
    write_json(out / "repositories.json", repos)
    write_json(out / "omissions.json", omitted)
    bundles = out / "git"
    bundles.mkdir()
    for name, meta in repos.items():
        repo = root / meta["path"]
        target = bundles / (name + ".bundle")
        git(repo, "bundle", "create", str(target), "--all")
        git(repo, "bundle", "verify", str(target))
        # Separate index and working-tree deltas retain the pre-commit distinction.
        (bundles / (name + ".staged.patch")).write_bytes(git(repo, "diff", "--cached", "--binary", "HEAD"))
        (bundles / (name + ".unstaged.patch")).write_bytes(git(repo, "diff", "--binary"))
    entries = {}
    with zipfile.ZipFile(out / "workspace.zip.partial", "x", zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as archive:
        for n, path in enumerate(files, 1):
            relative = path.relative_to(root).as_posix()
            secret_check(path)
            before = digest(path)
            archive.write(path, relative)
            if digest(path) != before:
                raise ValueError(f"Source changed while sealing: {relative}")
            entries[relative] = {"sha256": before, "bytes": path.stat().st_size}
            if n % 500 == 0:
                print(f"Sealed {n}/{len(files)} files", flush=True)
    (out / "workspace.zip.partial").rename(out / "workspace.zip")
    outputs = [p for p in out.rglob("*") if p.is_file()]
    write_json(out / "manifest.json", {
        "format": "rimworld-workspace-recovery-v1", "original_workspace": str(root),
        "offline_only": True, "workspace_files": entries,
        "capsule_files": {p.relative_to(out).as_posix(): digest(p) for p in outputs},
        "scope": "Five companion repositories, all local experiment records, current saves and local Mod assemblies; excludes caches, explicit pytest scratch directories, Python environments and private key/config filenames. No installed game or parent N.E.K.O host backup.",
        "limits": "Same-disk capsule is not protection against disk failure. Git bundles contain locally available history, not missing shallow ancestors. Filename/pattern scanning is not a comprehensive secret audit of historical Git objects. Original evidence paths are retained, not rewritten.",
    })
    result = verify(out)
    write_json(out / "VERIFIED.json", result)
    return result


def verify(out):
    data = json.loads((out / "manifest.json").read_text("utf-8"))
    for name, expected in data["capsule_files"].items():
        if digest(out / name) != expected:
            raise ValueError(f"Capsule checksum mismatch: {name}")
    with zipfile.ZipFile(out / "workspace.zip") as archive:
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError("Duplicate archive member")
        if set(archive.namelist()) != set(data["workspace_files"]):
            raise ValueError("Archive members differ from manifest")
        for name, meta in data["workspace_files"].items():
            if name.startswith("/") or ".." in Path(name).parts:
                raise ValueError("Unsafe archive member")
            with archive.open(name) as stream:
                if stream_digest(stream) != meta["sha256"]:
                    raise ValueError(f"Archived file checksum mismatch: {name}")
            if archive.getinfo(name).file_size != meta["bytes"]:
                raise ValueError(f"Archived file length mismatch: {name}")
    return {"verified": True, "workspace_files": len(data["workspace_files"]),
            "source_bytes": sum(x["bytes"] for x in data["workspace_files"].values()),
            "zip_bytes": (out / "workspace.zip").stat().st_size,
            "manifest_sha256": digest(out / "manifest.json"),
            "meaning": "Every ZIP member and capsule checksum verified; not an Agent quality claim or independent backup."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["inventory", "seal", "verify"])
    parser.add_argument("--workspace", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    root = args.workspace.resolve()
    if args.command == "inventory":
        files, repos, omitted = inventory(root)
        result = {"files": len(files), "bytes": sum(p.stat().st_size for p in files), "repositories": repos, "omitted": omitted}
    elif args.out is None:
        parser.error("--out required for seal and verify")
    elif args.command == "seal":
        result = seal(root, args.out.resolve())
    else:
        result = verify(args.out.resolve())
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
