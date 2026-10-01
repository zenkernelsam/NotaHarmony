# Phase 1431：assets/ 尾部轴收口报告（裁决阶段，零代码改动）

- 日期：2026-08-09
- 状态：完成（裁决阶段；Desktop Replay 6 项本 Phase 检查）
- 证据：`docs/migration/evidence/phase-1431-assets-tail.md`
- 决策：`docs/migration/adr/ADR-1366-assets-tail-closure.md`
- Replay：`docs/migration/replays/d02-original-assets-tail-sweep.mjs`

## 裁决结果

### spellcheck（en_words.dat + misspell 管线）：fail-closed

`bc1`→`v6n.h`→`fal.b`→`cji`→`ff7` 词典标注链虽完整，但
`NOTE_SPELLCHECK`（`h35.a1`）以 `qd5` = **DebugOnly** 构造：
`h45.b()` 仅调试/内部构建返真（`wki.C0` 生产恒 false），设置行
`check_spelling` 同被 `axg.java:115` 门控。词典不打包、不虚构渲染。

### vendored / 平台边界

iink `conf/*.conf`+`resources/*.res`（ADR-0645）、MLKit OCR 模型、
ART `baseline.prof(m)`、`ConversionRates.csv`（付费墙）、
OkHttp `PublicSuffixDatabase.list`、`brushpacks/`（ADR-1360）。

### 已移植确认

`glmath/`、`covers/`、`papertemplates/`、`planners/`、
`emojis_unicode.json`（Phase 1430）。

## 验证

本 Phase fixture 6/6；裁决阶段零代码改动；基线与双构建随验收复核。
`assets/` 轴至此全域收口。
