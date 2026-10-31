#!/usr/bin/env bash
# C-2B toolchain batch-01: SkVM on fixed samples (evidence script, re-runnable)
#
# 前置：
#   - Linux 或 WSL2（SkVM 无 win32 预编译二进制，Windows 原生安装会失败）
#   - Node >= 18；npm i -g @ipads-skvm/skvm
#   - 固定样本：把 c-2a-samples-v1.json 中 S04-S09 的 SKILL.md 放到 $WORK/skills/<name>/SKILL.md
# 用法：WORK=$HOME/c2b bash skvm-batch01.sh
export PATH="$HOME/opt/node-v20.19.1-linux-x64/bin:$PATH"
WORK="${WORK:-$HOME/c2b}"
LOG="$WORK/logs"
mkdir -p "$LOG"
RUNLOG="$LOG/batch01-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

echo "########## E0 environment ##########"
date -u +%Y-%m-%dT%H:%M:%SZ
uname -srm
node --version
npm --version
skvm --version
npm ls -g --depth=0 2>/dev/null | grep -i skvm
echo "cache root: $HOME/.skvm"
cat "$(command -v skvm | xargs dirname)/../lib/node_modules/@ipads-skvm/skvm/package.json" 2>/dev/null | head -20

echo
echo "########## E1 adapter enumeration (invalid adapter probe) ##########"
skvm aot-compile --skill="$WORK/skills/weather" --model=anthropic/claude-sonnet-4.6 \
  --adapter=harmonyos --pass=1 --dry-run 2>&1

echo
echo "########## E2 pass 1 (rewrite-skill) dry-run, adapter=openclaw, all samples ##########"
for n in weather trello meme-maker tmux mcporter peekaboo; do
  echo "----- $n -----"
  skvm aot-compile --skill="$WORK/skills/$n" --model=anthropic/claude-sonnet-4.6 \
    --adapter=openclaw --pass=1 --dry-run 2>&1
done

echo
echo "########## E3 pass 2 (bind-env) dry-run, no TCP expected ##########"
for n in weather tmux; do
  echo "----- $n -----"
  skvm aot-compile --skill="$WORK/skills/$n" --model=anthropic/claude-sonnet-4.6 \
    --adapter=openclaw --pass=bind-env --dry-run 2>&1
done

echo
echo "########## E4 real bind-env run (no dry-run), weather ##########"
skvm aot-compile --skill="$WORK/skills/weather" --model=anthropic/claude-sonnet-4.6 \
  --adapter=openclaw --pass=bind-env 2>&1
echo "exit=$?"

echo
echo "########## E5 config doctor ##########"
skvm config doctor 2>&1 | head -40

echo
echo "LOG=$RUNLOG"
