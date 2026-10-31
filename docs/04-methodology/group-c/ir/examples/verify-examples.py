"""Static consistency checks; no Skill or Harmony execution."""
import argparse
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--survey", type=Path, required=True)
args = parser.parse_args()
samples = json.loads(Path(__file__).with_name("skill-ir-examples-v0.json").read_text(encoding="utf-8"))["samples"]
survey = {r["id"]: r for r in json.loads(args.survey.read_text(encoding="utf-8"))}
expected = {"bundled:weather", "bundled:trello", "bundled:meme-maker",
            "bundled:tmux", "bundled:mcporter", "bundled:peekaboo",
            "clawhub:perpetualhui/adaptive-socratic-questioning",
            "clawhub:aircraft06/academic-paper-writing-style",
            "clawhub:clawdiri-ai/davinci-first-principles"}
assert len(samples) == 9 and {s["source"]["record_id"] for s in samples} == expected
assert len({s["id"] for s in samples}) == 9
assert len({s["binding"]["registration"]["name"] for s in samples}) == 9

def declared(v):
    return None if v == "未声明" else [p.strip() for p in v.split(";")]

for s in samples:
    r = survey[s["source"]["record_id"]]
    for a, b in [("version", "version"), ("skill_md_sha256", "sha256"), ("frontmatter_name", "name")]:
        assert s["source"][a] == r[b], (s["id"], a)
    assert s["source"]["registry_slug"] == (r["registry_slug"] or None)
    assert re.fullmatch(r"[0-9a-f]{64}", s["source"]["skill_md_sha256"])
    d = s["dependencies"]["source_declared"]
    for a, b in [("bins_all", "requires_bins_all"), ("bins_any", "requires_bins_any"),
                 ("env_all", "requires_env"), ("config_all", "requires_config")]:
        assert d[a] == declared(r[b]), (s["id"], a)
    assert d["primary_env"] == (None if r["primary_env"] == "未声明" else r["primary_env"])
    for field in ["classification_status", "original_runtime_status", "harmony_runtime_status"]:
        assert s["assessment"][field] == r[field]
    assert s["assessment"]["portability"] == r["portability"]
    assert s["assessment"]["original_runtime_status"] == "未运行"
    assert s["assessment"]["harmony_runtime_status"] == "未运行"
    if s["scope"]["mode"] != "full":
        assert s["scope"]["parent_record"] == r["id"] and s["id"] != r["id"]
        assert s["scope"]["excluded"]
    b = s["binding"]
    if s["scope"]["mode"] == "remote-host":
        assert s["scope"]["execution_location"].startswith("remote-")
        assert "ohos.permission.INTERNET" in b["app_permissions"]
    assert b["status"] == "pending-verification"
    name = b["registration"]["name"]
    assert re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) and len(name.encode()) <= 64
    assert b["entry"]["module_file"] == "skills/" + name + "/" + b["entry"]["scriptPath"]
    assert b["registration"]["srcEntries"] is None
    assert b["entry"]["functions"] == [o["operation"] for o in s["task"]["operations"]]
    for o in s["task"]["operations"]:
        for i, p in enumerate(o["parameters"]):
            assert p["target_arg"] == "arg" + str(i+1) and p["argv_index"] == i
    assert s["gaps"] and s["test_plan"]["cases"]
    assert not s["evidence"]["target_logs"] and not s["evidence"]["reviewers"]
by_source = {s["source"]["record_id"]: s for s in samples}
assert by_source["bundled:weather"]["dependencies"]["source_declared"]["bins_all"] is None
assert by_source["bundled:trello"]["dependencies"]["source_declared"]["bins_all"] == ["curl", "jq"]
assert by_source["clawhub:clawdiri-ai/davinci-first-principles"]["source"]["frontmatter_name"] == "first-principles"
assert "PNG/Playwright/Chromium" in by_source["bundled:meme-maker"]["scope"]["excluded"]
print("PASS: 9 fixed samples; provenance, dependencies, scope, bindings, arguments, evidence-state consistency.")
print("NOT CHECKED: core Schema, source instruction equivalence, SDK build, runtime calls, performance.")
