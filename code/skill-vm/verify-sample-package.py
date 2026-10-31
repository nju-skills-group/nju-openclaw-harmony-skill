#!/usr/bin/env python3
"""Cross-verify local sample packages against two independent 乙组 artifacts.

Inputs
  --root      directory holding one sub-directory per skill (e.g. an OpenClaw
              package's skills/ dir, or an unpacked ClawHub release)
  --samples   C-2A sample list (c-2a-samples-v1.json)
  --manifest  乙组 source-manifest.json (per-file sha256)
  --tree      乙组 bundled-tree.json (git tree at the pinned commit: blob sha1 + size)

Checks, per bundled sample:
  1. local SKILL.md sha256 == samples JSON skill_md_sha256
  2. local file git-blob sha1 == tree blob sha1 (lineage to the pinned commit)
  3. local file sha256 == manifest sha256 (independent second hash)

Exit code 0 only when every checked file passes all applicable checks.
"""
import argparse
import hashlib
import json
from pathlib import Path


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, type=Path)
    ap.add_argument("--samples", required=True, type=Path)
    ap.add_argument("--manifest", required=True, type=Path)
    ap.add_argument("--tree", required=True, type=Path)
    ap.add_argument("--json-out", type=Path)
    args = ap.parse_args()

    plan = json.loads(args.samples.read_text("utf-8"))
    manifest = json.loads(args.manifest.read_text("utf-8"))
    tree = json.loads(args.tree.read_text("utf-8"))

    blobs = {e["path"]: e for e in tree["tree"]["tree"] if e["type"] == "blob"}
    by_path = {}
    for e in manifest["source_files"]:
        by_path.setdefault(e["path"], []).append(e["sha256"])

    rows, failures = [], 0
    for s in plan["samples"]:
        if not s["source_id"].startswith("bundled:"):
            continue
        name = s["source_id"].split(":", 1)[1]
        skill_dir = args.root / name
        if not skill_dir.is_dir():
            print(f"[SKIP] {s['sample_id']} {name}: not present in {args.root}")
            continue
        for f in sorted(p for p in skill_dir.rglob("*") if p.is_file()):
            rel = f.relative_to(args.root).as_posix()
            data = f.read_bytes()
            sha = hashlib.sha256(data).hexdigest()
            t = blobs.get(rel)
            row = {
                "sample_id": s["sample_id"], "path": rel, "bytes": len(data), "sha256": sha,
                "sample_list": sha == s["skill_md_sha256"] if rel.endswith("/SKILL.md") else None,
                "tree": bool(t) and git_blob_sha1(data) == t["sha"] and len(data) == t["size"],
                "manifest": sha in by_path.get(rel, []),
            }
            rows.append(row)
            ok = row["manifest"] and row["tree"] and row["sample_list"] is not False
            failures += 0 if ok else 1
            print(f"[{'ok' if ok else 'FAIL'}] {s['sample_id']} {rel} {len(data)} B tree={row['tree']} "
                  f"manifest={row['manifest']}")

    if args.json_out:
        args.json_out.write_text(json.dumps(rows, ensure_ascii=False, indent=2), "utf-8")
    print(f"checked {len(rows)} files, failures={failures}")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
