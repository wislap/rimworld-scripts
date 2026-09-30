"""Offline checks for recovery integrity and preserving native evidence."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import workspace_checkpoint as checkpoint


class RecoveryTests(unittest.TestCase):
    def test_secret_scan_uses_a_token_boundary_and_checks_gzip(self):
        import gzip
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "trace.json.gz"
            path.write_bytes(gzip.compress(b'task-' + b'x' * 32))
            checkpoint.secret_check(path)
            path.write_bytes(b"intentionally-invalid-gzip-test-fixture")
            checkpoint.secret_check(path)
            path.write_bytes(gzip.compress(b'"sk-' + b'x' * 32 + b'"'))
            with self.assertRaisesRegex(ValueError, "Credential-shaped"):
                checkpoint.secret_check(path)

    def test_member_tampering_is_detected_even_with_valid_zip(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp)
            archive = out / "workspace.zip"
            with zipfile.ZipFile(archive, "w") as stream:
                stream.writestr("evidence.json", b"altered")
            manifest = {
                "workspace_files": {"evidence.json": {"sha256": hashlib.sha256(b"original").hexdigest(), "bytes": 8}},
                "capsule_files": {"workspace.zip": checkpoint.digest(archive)},
            }
            (out / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Archived file checksum"):
                checkpoint.verify(out)

    def test_cache_exclusion_keeps_native_binaries_and_failed_receipts(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for name in ["study/bin/FrozenWorld.dll", "study/runs/failed.json", "study/venv/disposable.py", "study/__pycache__/cache.pyc"]:
                path = root / ".bench-results" / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture", encoding="utf-8")
            scratch = root / ".bench-results/judge-pilot-test-20260930-1/fixture.txt"
            scratch.parent.mkdir(parents=True)
            scratch.write_text("rebuildable fixture", encoding="utf-8")
            with patch.object(checkpoint, "REPOS", {}):
                files, _, omitted = checkpoint.inventory(root)
            self.assertEqual({p.relative_to(root).as_posix() for p in files}, {
                ".bench-results/study/bin/FrozenWorld.dll", ".bench-results/study/runs/failed.json"})
            self.assertEqual(len(omitted), 3)

    def test_seal_refuses_existing_output(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError, "never overwritten"):
                checkpoint.seal(Path(temp), Path(temp))


if __name__ == "__main__":
    unittest.main()
