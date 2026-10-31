#!/usr/bin/env bash
# C-2B 产物质量核对：统计源 SKILL.md 与各目标产物中"行内代码标识"的保留情况
# 用法：先跑 skcc-batch02.sh 生成 $WORK/out，再 WORK=$HOME/c2b bash skcc-verify-loss.sh
WORK="${WORK:-$HOME/c2b}"
W="$WORK/out"
S="$WORK/skills/weather/SKILL.md"

echo "== 出现次数（源 vs 各产物）=="
printf 'source  web_fetch=%s backticks=%s\n' \
  "$(grep -o 'web_fetch' "$S" | wc -l)" "$(grep -o '`' "$S" | wc -l)"
for t in claude codex gemini kimi; do
  f=$(find "$W/$t" -name '*.md' | head -1)
  printf '%-7s file=%s web_fetch=%s backticks=%s\n' \
    "$t" "$(basename "$f")" "$(grep -o 'web_fetch' "$f" | wc -l)" "$(grep -o '`' "$f" | wc -l)"
done

echo
echo "== claude 产物中的空洞行（行内标识被剥离）=="
grep -n 'Use  first\|summarize , \|If  has reliability' "$W/claude/SKILL.md" | head

echo
echo "== 依赖声明是否保留（源 frontmatter 的 metadata.openclaw.install）=="
grep -c 'openclaw' "$W/claude/SKILL.md" "$W/codex/weather.md" 2>/dev/null

echo
echo "== gemini 侧车配置 =="
cat "$W/gemini/assets/config.yaml" 2>/dev/null
