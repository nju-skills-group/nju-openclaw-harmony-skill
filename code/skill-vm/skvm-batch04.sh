#!/usr/bin/env bash
# C-2B toolchain batch-04 (local): SkVM against the three L1 samples.
#
# 批次 03 的表格里 SkVM 一列写的是 "阻断 6/9，未测 3/9（S01–S03 未补跑）"。
# 本脚本补的就是这 3 个"未测"：在**同一环境**下对 S01–S03 各跑一次 pass-1 dry-run，
# 把"未测"变成有原文、有退出码的"阻断"（或意外通过）。
#
# 前置：WSL2 + Node 20/24 + `npm i -g @ipads-skvm/skvm`；样本已由
#       fetch-samples-clawhub.py 取到 $WORK/samples-clawhub，并 stage 到 $WORK/skills-l1。
# 用法：WORK=$HOME/c2b bash skvm-batch04.sh
set -u
NODE_PREFIX="${NODE_PREFIX:-$HOME/opt/node-v20.19.1-linux-x64}"
export PATH="$NODE_PREFIX/bin:$PATH"
WORK="${WORK:-$HOME/c2b}"
STAGE="$WORK/skills-l1"
LOG="$WORK/logs"
mkdir -p "$LOG"
RUNLOG="$LOG/batch04-skvm-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

ids="S01 S02 S03"

echo "########## E0 environment ##########"
date -u +%Y-%m-%dT%H:%M:%SZ
uname -srm
node --version
npm --version
skvm --version
node -e 'const p=require(process.argv[1]+"/lib/node_modules/@ipads-skvm/skvm/package.json");console.log("pkg",p.name,p.version)' "$NODE_PREFIX"
echo "cache root: $HOME/.skvm"

echo
echo "########## E1 profile 能力核对（缺的是 profile 还是密钥？）##########"
skvm profile --help 2>&1 | head -25
echo "--- 现有 profile ---"
skvm profile list 2>&1 | head -20
echo "--- 配置诊断 ---"
skvm config doctor 2>&1 | head -30

echo
echo "########## E2 输入绑定（哈希必须与样本清单一致）##########"
for id in $ids; do
  f="$STAGE/$id/SKILL.md"
  if [ -f "$f" ]; then
    echo "$id $(sha256sum "$f" | cut -d' ' -f1) files=$(find "$STAGE/$id" -type f | wc -l)"
  else
    echo "$id MISSING $f"
  fi
done

echo
echo "########## E3 每样本 pass-1 dry-run（adapter=openclaw）##########"
for id in $ids; do
  echo "----- $id -----"
  skvm aot-compile --skill="$STAGE/$id" \
    --model=anthropic/claude-sonnet-4.6 --adapter=openclaw --pass=1 --dry-run \
    >"$WORK/logs/.skvm-$id.txt" 2>&1
  rc=$?
  echo "exit=$rc"
  tail -6 "$WORK/logs/.skvm-$id.txt"
done

echo
echo "########## E4 adapter=harmonyos 是否存在（工具侧目标集合）##########"
skvm aot-compile --skill="$STAGE/S01" --model=anthropic/claude-sonnet-4.6 \
  --adapter=harmonyos --pass=1 --dry-run >"$WORK/logs/.skvm-harmonyos.txt" 2>&1
echo "exit=$?"
tail -3 "$WORK/logs/.skvm-harmonyos.txt"

echo
echo "########## E5 判定表 ##########"
for id in $ids; do
  if grep -q "Missing profiles" "$WORK/logs/.skvm-$id.txt" 2>/dev/null; then
    state="阻断（切 pass-1 前即要求已注册 profile，缺 provider 凭证）"
  elif grep -q "Invalid adapter" "$WORK/logs/.skvm-$id.txt" 2>/dev/null; then
    state="失败（adapter 不被接受）"
  else
    state="见 .skvm-$id.txt（本批未预期）"
  fi
  echo "$id: $state"
done

echo
echo "LOG=$RUNLOG"
