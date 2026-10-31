#!/usr/bin/env bash
# OpenClaw original-platform baseline probe (C-2B batch 02).
#
# Installs nothing by itself unless OPENCLAW_INSTALL=1; the point is to record
# the platform version, which of the nine samples the platform can actually
# load, and the per-skill missing requirements. It never calls a model, so it
# needs no API key. Use it before writing any 原平台基线 record.
#
#   OPENCLAW_INSTALL=1 bash openclaw-baseline.sh
#
# Findings it produced on 2026-10-31 (Ubuntu 20.04, node 24.22.1):
#   total 55 / eligible 20 / model-visible 20 / missing 35
#   weather, meme-maker, tmux eligible; trello missing jq+TRELLO_*; mcporter
#   missing the mcporter bin; peekaboo platformIncompatible (os: darwin only).
set -uo pipefail
VERSION="${OPENCLAW_VERSION:-2026.10.9}"
WORK="${WORK:-$HOME/c2b}"
LOGS="$WORK/logs"
OUT="$WORK/oc"
SKILLS=(weather trello meme-maker tmux mcporter peekaboo)
mkdir -p "$LOGS" "$OUT"

# Expected SKILL.md sha256 from the C-2A sample list (c-2a-samples-v1.json).
declare -A EXPECT=(
  [weather]=62ab4821aa873949d1c1091836be1659a42b32caadce4bd145f5505a1ceaeec1
  [trello]=dc524f73bd87b8089d061187bb26add41101ee82e288a1597a2d7b89fd934222
  [meme-maker]=682db7cba34a3d3ca791f7cccaee9488810c731d6622d8886a9bcca77c59d2f3
  [tmux]=8aeaa6f3dfe06d58e09721778b8c9e654bcbd47590f26f442c4dc87c9349c572
  [mcporter]=010ed9b265e58d45d1e95e6deac5e60b1e46e6ebab00fc3fe30429a1048e236e
  [peekaboo]=4369238bd780adc502acc48eef83a41d1a5fb8e6369b6cd258e11779043bfcb4
)

echo "== versions =="
node -v; npm -v
if ! command -v openclaw >/dev/null; then
  if [ "${OPENCLAW_INSTALL:-0}" = "1" ]; then
    echo "installing openclaw@$VERSION"
    npm i -g "openclaw@$VERSION" --no-fund --no-audit --loglevel=error
  else
    echo "openclaw not installed; rerun with OPENCLAW_INSTALL=1 (needs node >= 24.22.1)"
    exit 2
  fi
fi
openclaw --version

echo "== skills check =="
openclaw skills check --json > "$LOGS/oc-skills-check.json" 2>"$LOGS/oc-skills-check.err"
echo "exit=$? bytes=$(wc -c <"$LOGS/oc-skills-check.json")"
python3 - "$LOGS/oc-skills-check.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
s = d["summary"]
print("total={total} eligible={eligible} modelVisible={modelVisible} "
      "commandVisible={commandVisible} missing={missingRequirements}".format(**s))
PY

echo "== per-skill state + content hash =="
PKG="$(npm root -g 2>/dev/null)/openclaw"
for s in "${SKILLS[@]}"; do
  openclaw skills info "$s" --json > "$LOGS/oc-info-$s.json" 2>&1
  got=""
  if [ -n "$PKG" ] && [ -f "$PKG/skills/$s/SKILL.md" ]; then
    got="$(sha256sum "$PKG/skills/$s/SKILL.md" | cut -d' ' -f1)"
  fi
  python3 - "$LOGS/oc-info-$s.json" "$s" "${EXPECT[$s]}" "$got" <<'PY'
import json, sys
path, name, expect, got = sys.argv[1:5]
d = json.load(open(path))
flag = "OK" if got and got == expect else "HASH-MISMATCH"
print("{:11s} eligible={:5s} modelVisible={:5s} incompatible={:5s} missing={} hash={} [{}]".format(
    name, str(d.get("eligible")), str(d.get("modelVisible")),
    str(d.get("platformIncompatible")), json.dumps(d.get("missing") or {}, ensure_ascii=False), got[:12], flag))
PY
done

echo "== model auth (expected to fail without a provider key) =="
openclaw models status 2>&1 | sed -n '1,20p' | tee "$LOGS/oc-models-status.txt"

echo "== log hashes =="
sha256sum "$LOGS"/oc-*.json "$LOGS"/oc-models-status.txt 2>/dev/null
