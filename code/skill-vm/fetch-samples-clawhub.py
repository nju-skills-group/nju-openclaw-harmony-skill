#!/usr/bin/env python3
"""Fetch version-pinned ClawHub samples (S01-S03) read-only, verifying every file.

Endpoint recipe comes from 乙组 tools/skill-survey/scripts/fetch_candidates.py:
  GET /api/v1/skills/<slug>?ownerHandle=<owner>
  GET /api/v1/skills/<slug>/versions/<version>?ownerHandle=<owner>   -> version.files[].sha256
  GET /api/v1/skills/<slug>/file?path=<path>&version=<version>&ownerHandle=<owner>

Refuses to keep a file whose sha256 differs from the release inventory, and
refuses a sample whose SKILL.md differs from the C-2A sample list.

Usage:
  python fetch-samples-clawhub.py --samples <c-2a-samples-v1.json> --out <dir>
"""
import argparse
import hashlib
import json
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://clawhub.ai/api/v1/skills/"
UA = {"User-Agent": "NJU-Skill-Survey/1.0 (public read-only coursework)"}


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--samples", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--only", nargs="*", help="sample ids, default all clawhub:* entries")
    args = ap.parse_args()

    plan = json.loads(args.samples.read_text("utf-8"))
    targets = [
        s for s in plan["samples"]
        if s["source_id"].startswith("clawhub:") and (not args.only or s["sample_id"] in args.only)
    ]
    if not targets:
        print("no clawhub samples selected")
        return 2

    report, failures = [], 0
    for s in targets:
        owner, slug = s["source_id"].split(":", 1)[1].split("/", 1)
        version = s["version"]
        q = urllib.parse.urlencode({"ownerHandle": owner})
        detail = json.loads(get(f"{API}{slug}?{q}"))
        release = json.loads(get(f"{API}{slug}/versions/{version}?{q}"))
        actual_owner = (detail.get("owner") or {}).get("handle")
        if actual_owner and actual_owner != owner:
            print(f"[FAIL] {s['sample_id']} publisher {actual_owner} != {owner}")
            failures += 1
            continue
        files = (release.get("version") or release).get("files") or []
        if not files:
            print(f"[FAIL] {s['sample_id']} release has no file inventory")
            failures += 1
            continue
        folder = args.out / owner / slug / version
        (folder).mkdir(parents=True, exist_ok=True)
        (folder / "detail.json").write_text(json.dumps(detail, ensure_ascii=False, indent=2), "utf-8")
        (folder / "version.json").write_text(json.dumps(release, ensure_ascii=False, indent=2), "utf-8")
        entry = {"sample_id": s["sample_id"], "owner": owner, "slug": slug, "version": version,
                 "files": len(files), "bytes": 0, "skill_md_sha256": None, "ok": True}
        for f in files:
            path = f["path"]
            url = f"{API}{slug}/file?" + urllib.parse.urlencode(
                {"path": path, "version": version, "ownerHandle": owner})
            data = get(url)
            digest = hashlib.sha256(data).hexdigest()
            if f.get("sha256") and digest != f["sha256"]:
                print(f"[FAIL] {s['sample_id']} {path} sha256 mismatch")
                entry["ok"] = False
                failures += 1
                continue
            dest = folder / "source" / path
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            entry["bytes"] += len(data)
            if path == "SKILL.md":
                entry["skill_md_sha256"] = digest
                if digest != s["skill_md_sha256"]:
                    print(f"[FAIL] {s['sample_id']} SKILL.md != sample list")
                    entry["ok"] = False
                    failures += 1
        report.append(entry)
        print(f"[{'ok' if entry['ok'] else 'FAIL'}] {s['sample_id']} {owner}/{slug}@{version} "
              f"{entry['files']} files {entry['bytes']} B -> {folder}")

    (args.out / "clawhub-fetch-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), "utf-8")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
