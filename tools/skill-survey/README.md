# 普查工具

工具只读取公开目录和源码、生成本地数据，不安装或执行被调查的 Skill。

## 固定数据重放

在研究仓库根目录运行，Python 3.10+：

```powershell
python -m pip install -r tools/skill-survey/requirements.txt
$env:SKILL_SURVEY_OUTPUT = Join-Path (Get-Location).Path 'docs/04-methodology/group-b/skill-survey'
python tools/skill-survey/scripts/fetch_bundled.py
python tools/skill-survey/scripts/fetch_candidates.py
python tools/skill-survey/scripts/build_inventory.py
python tools/skill-survey/scripts/verify_inventory.py
python -m unittest discover -s tools/skill-survey/scripts -p test_catalog_triage.py -v
```

前两步从固定 commit／版本下载分析对象，不执行其内容。源码缓存不入库。目录初筛重放使用已入库的 `data/catalog-input.jsonl.gz`，无需重新读取实时目录；其 SHA-256 和条数见报告 `source-manifest.json`。

生成的全量 CSV/JSONL 是压缩报告的展开版本，无需重复提交。重放时没有原始分页缓存，因此验证会如实记录 `raw_pagination_rechecked: false`；首轮采集时的 36 分区、结束游标与校验结果已在报告中保存。

## 更新另一日期的数据

在独立副本中运行 `fetch_clawhub_prefixes.py`，等待 36 个分区全部结束，再运行 `select_samples.py` 和后续步骤。实时更新会改变目录、版本和数量，不能称为重现 2026-10-25 的原子快照。修改样本计划时，需同步逐项判读，生成器会检查二者集合相等。

## 数据角色

- `catalog-input.jsonl.gz`：公开 API 原始条目输入，83,265 条；包含发布者摘要，不作为指令执行。
- `catalog-coverage.json`：首轮遍历各分区状态。
- `bundled-review.json`、`clawhub-review.json`：源码静态分类判断与理由。
- `sampling-plan.json`：8 类目的性选样，每类 3 个；不是随机抽样。
- `bundled-tree.json`：固定官方目录的文件清单与 Git blob 哈希。

初筛规则输出的是摘要线索；源码分级来自逐项判读。两者字段独立，原平台／鸿蒙运行结果也独立。
