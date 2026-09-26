# ADR-0725 — 原版 1.4.2 工具/学习键增量 + Phase 760 更正

日期：2026-09-29
状态：已登记（含上游更正；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-781-original-tools-learn-key-delta.md`
Replay：`docs/migration/replays/d02-original-tools-learn-key-delta.mjs`

## 背景

`ui_tools__`/`ui_learn__` 键差收尾：34 个 ui_tools 新键中
除形状/钢笔族（Phase 776/778）外尚有胶带图案命名、笔刷包名、
工具箱细化键；`ui_learn__` 差集暴露 Phase 760 结论错误。

## 决策

1. **更正**：Learn AI 聊天**未下线**——`feature_learn__*` 键
   迁移至 `ui_learn__*` 命名空间；真删仅
   transcription error_format 一键。Phase 760 证据已加注。
2. **胶带图案名**：Harmony TapePattern 九值与键序逐一对应、
   TapePatternPicker 已全量移植——记为**已对齐面**，1.4.2
   仅补名称串，无回移动作。
3. 其余工具箱键：版本差登记。

## 后果

- 消除一条错误结论对后续移植决策的误导（若按"已下线"
  处理会在 T-042 漏报聊天存续）。
- Replay 钉住更正证据 + 九图案已移植对应。
