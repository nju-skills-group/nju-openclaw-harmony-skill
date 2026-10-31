#!/usr/bin/env bash
# C-2B toolchain batch-02: SkCC (nexa-skill) 构建 + validate + 逐目标编译
#
# 前置：
#   - Rust 工具链（rustc 1.85+）；npm 包 nexa-skill-compiler 只是壳，必须先构建 Rust CLI
#   - git clone https://github.com/Nexa-Language/Skill-Compiler && cargo install --path nexa-skill-cli
#   - 固定样本同 skvm-batch01.sh
# 用法：WORK=$HOME/c2b bash skcc-batch02.sh
export PATH="$HOME/.cargo/bin:$PATH"
WORK="${WORK:-$HOME/c2b}"
LOG="$WORK/logs"
mkdir -p "$LOG"
RUNLOG="$LOG/batch02-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

echo "########## E0 environment ##########"
date -u +%Y-%m-%dT%H:%M:%SZ
uname -srm
nexa-skill --version
rustc --version
cargo --version
git -C "$WORK/Skill-Compiler" rev-parse HEAD 2>/dev/null

echo
echo "########## E1 CLI 目标集合 ##########"
nexa-skill build --help 2>&1

echo
echo "########## E2 不存在的 --target 探测（记录文档与实现漂移） ##########"
nexa-skill build "$WORK/skills/weather/SKILL.md" --target claude 2>&1
echo "exit=$?"

echo
echo "########## E3 validate 六个样本 ##########"
for n in weather trello meme-maker tmux mcporter peekaboo; do
  echo "----- $n -----"
  nexa-skill validate "$WORK/skills/$n/SKILL.md" 2>&1 | grep -E 'Validate|Error|error' | head -3
done

echo
echo "########## E4 逐目标编译 weather ##########"
OUT="$WORK/out"; rm -rf "$OUT"; mkdir -p "$OUT"
for t in claude codex gemini kimi; do
  echo "===== $t ====="
  nexa-skill build "$WORK/skills/weather/SKILL.md" --$t -o "$OUT/$t" 2>&1 | tail -6
done
echo "===== --all ====="
nexa-skill build "$WORK/skills/weather/SKILL.md" --all -o "$OUT/all" 2>&1 | tail -6
echo "===== tmux (L3, 含脚本) --claude ====="
nexa-skill build "$WORK/skills/tmux/SKILL.md" --claude -o "$OUT/tmux-claude" 2>&1 | tail -4

echo
echo "########## E5 产物哈希 ##########"
find "$OUT" -type f -exec sha256sum {} \; | sort

echo
echo "########## E6 manifest（含工具自报 source_hash） ##########"
cat "$OUT/claude/manifest.json"
echo "LOG=$RUNLOG"
