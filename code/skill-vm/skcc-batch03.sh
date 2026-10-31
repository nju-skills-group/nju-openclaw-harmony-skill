#!/usr/bin/env bash
# C-2B toolchain batch-03: SkCC on the three L1 (ClawHub) samples.
#
# Batch 01/02 only covered S04-S09 (bundled). Batch 03 closes that gap with the
# packages fetched by fetch-samples-clawhub.py.
#
#   python fetch-samples-clawhub.py --samples <c-2a-samples-v1.json> --out "$WORK/samples-clawhub"
#   WORK=$HOME/c2b bash skcc-batch03.sh
#
# Expects $WORK/Skill-Compiler (Rust CLI already installed as `nexa-skill`).
set -u
export PATH="$HOME/.cargo/bin:$PATH"
WORK="${WORK:-$HOME/c2b}"
SRC="${SRC:-$WORK/samples-clawhub}"
LOG="$WORK/logs"
mkdir -p "$LOG"
RUNLOG="$LOG/batch03-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

# sample_id | owner | slug | version
SAMPLES=(
  "S01 perpetualhui adaptive-socratic-questioning 1.1.0"
  "S02 aircraft06 academic-paper-writing-style 1.0.0"
  "S03 clawdiri-ai davinci-first-principles 1.0.0"
)

echo "########## E0 environment ##########"
date -u +%Y-%m-%dT%H:%M:%SZ
uname -srm
nexa-skill --version
rustc --version | head -1
git -C "$WORK/Skill-Compiler" rev-parse HEAD 2>/dev/null

echo
echo "########## E1 stage sources ##########"
STAGE="$WORK/skills-l1"
rm -rf "$STAGE"; mkdir -p "$STAGE"
for row in "${SAMPLES[@]}"; do
  set -- $row
  id=$1; owner=$2; slug=$3; ver=$4
  d="$SRC/$owner/$slug/$ver/source"
  if [ ! -f "$d/SKILL.md" ]; then echo "MISSING $id ($d)"; continue; fi
  mkdir -p "$STAGE/$id"
  cp -r "$d/." "$STAGE/$id/"
  echo "$id $(sha256sum "$STAGE/$id/SKILL.md" | cut -d' ' -f1) files=$(find "$STAGE/$id" -type f | wc -l)"
done

echo
echo "########## E2 validate ##########"
for row in "${SAMPLES[@]}"; do
  set -- $row
  echo "----- $1 -----"
  nexa-skill validate "$STAGE/$1/SKILL.md" 2>&1 | grep -Ei 'validate|error' | head -4
  echo "exit=$?"
done

echo
echo "########## E3 build --claude ##########"
OUT="$WORK/out-l1"; rm -rf "$OUT"; mkdir -p "$OUT"
for row in "${SAMPLES[@]}"; do
  set -- $row
  echo "===== $1 ====="
  nexa-skill build "$STAGE/$1/SKILL.md" --claude -o "$OUT/$1-claude" 2>&1 | tail -5
done
echo "===== S03 --all（四目标，最小样本）====="
nexa-skill build "$STAGE/S03/SKILL.md" --all -o "$OUT/S03-all" 2>&1 | tail -5

echo
echo "########## E4 artifact hashes ##########"
find "$OUT" -type f -exec sha256sum {} \; | sort

echo
echo "########## E5 content-loss check ##########"
for row in "${SAMPLES[@]}"; do
  set -- $row
  id=$1
  src="$STAGE/$id/SKILL.md"
  art=$(find "$OUT/$id-claude" -name 'SKILL.md' | head -1)
  [ -z "$art" ] && { echo "$id: no SKILL.md artifact"; continue; }
  echo "----- $id -----"
  echo "backticks src=$(grep -o '`' "$src" | wc -l) out=$(grep -o '`' "$art" | wc -l)"
  echo "lines     src=$(wc -l <"$src") out=$(wc -l <"$art")"
  for f in followup_questions reasoning_path misconception_flags teacher_guidance; do
    printf 'field %-22s src=%s out=%s\n' "$f" "$(grep -c "$f" "$src")" "$(grep -c "$f" "$art")"
  done
done

echo
echo "########## E6 manifest (S03-claude) ##########"
cat "$OUT/S03-claude/manifest.json" 2>/dev/null
echo "LOG=$RUNLOG"
