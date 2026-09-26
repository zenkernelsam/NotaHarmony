# Phase 781 — 原版 1.4.2 工具/学习键增量 + Phase 760 更正

日期：2026-09-29
状态：完成（证据 + ADR + Replay + 上游注记；无源码变更）
证据：`docs/migration/evidence/phase-781-original-tools-learn-key-delta.md`
ADR：`ADR-0725-original-tools-learn-key-delta.md`
Replay：`d02-original-tools-learn-key-delta.mjs`（8/8）

## 本阶段做了什么

收尾 `ui_tools__`/`ui_learn__` 键差，并更正 Phase 760 的
Learn 下线结论。

## 发现

- **更正**：Learn AI 聊天未下线——chat/send/upsell 键幸存、
  error 等迁至 `ui_learn__*`；归一化后真删仅
  transcription error_format。Phase 760 证据/报告已加注。
- 胶带九图案获本地化名称（checkers→waves）；Harmony
  TapePattern 枚举 0-8 与键序逐一对应，TapePatternPicker
  早已全量移植——**已对齐面**，仅缺名称串。
- 其余工具箱键：brush_pack_{glitter,rainbow}、color_hex、
  no_color、reset、tool_with_effects 等——版本差登记。

## 分类

- 胶带图案：已移植（无动作）。
- Learn 存续更正：上游文档注记完成。
- 工具箱细化键：版本差登记。

## 验收

- Replay 8/8 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
