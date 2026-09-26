# ADR-0736 — 原版 1.4.2 内置拼写检查 + planner 资产登记

日期：2026-09-29
状态：已登记（版本差，纯本地可移植候选）
证据：`docs/migration/evidence/phase-792-original-spellcheck-planners.md`
Replay：`docs/migration/replays/d02-original-spellcheck-planners.mjs`

## 背景

assets/ 收尾：1.4.2 新增 `spellcheck/en_words.dat`（gzip
压缩 ~126k 英文词表）与 `planners/`（双起始日学术计划
本 PDF），`conf-lite/` 移除（MyScript lite）。

## 决策

- 拼写检查链路（bc1 词典加载 → fal 批量判定 → cji Flow
  装饰）为**纯本地**功能：`feature_settings__check_spelling`
  开关 + 词库资产即可运行，无后端依赖。登记为本地可行
  版本差；Harmony 无对应实现，待 T-042 窗口决策。
- planner PDF 归 782 簇（周起始切换 UI 证据闭环）。
- conf-lite 移除归 760/768 MyScript 远端化佐证。

## 后果

- assets/ 目录全量归属完毕。
- 拼写检查为首个纯本地可移植的 1.4.2 增量功能登记
  （此前本地增量如形状选择器/书法笔均已确认）。
