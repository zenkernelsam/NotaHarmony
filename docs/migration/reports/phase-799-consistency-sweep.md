# Phase 799 — 文档-代码一致性清扫（fixture 引用面）

日期：2026-09-29
状态：完成（证据 + ADR + Replay；不改 Harmony 功能源码）
证据：`docs/migration/evidence/phase-799-consistency-sweep.md`
ADR：`ADR-0743-consistency-sweep.md`
Replay：`d02-consistency-fixture-references.mjs`（4/4）

## 本阶段做了什么

对 adr/evidence/replays/reports 做全量交叉引用扫描并
修正三类不一致。

## 发现与修正

- feature-note-tail 软引用失效 ADR 名 + `|| true`
  恒真断言 → 改读 ADR-0658 并断言实质内容。
- ADR-0670 两处 "ADR-0513" 陈旧引用 → 改 ADR-0658。
- 9 个孤儿 fixture（fix 提交来源）入册为独立回归集。
- 正向面：156 个代码锚点 0 断链。

## 验收

- 修正后 feature-note-tail 30 检全绿；
  一致性 fixture 4/4 绿；全量套件与双 HAP 随本阶段执行。
