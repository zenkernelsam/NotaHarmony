# Phase 773 — 原版 1.4.2 文本专属模式登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-773-original-text-only-mode.md`
ADR：`ADR-0717-original-text-only-mode.md`
Replay：`d02-original-text-only-mode.mjs`（6/6）

## 本阶段做了什么

Phase 767 列增量中的 `NoteStateEntity.isTextOnly` 经查为完整
功能面——本阶段恢复其完整语义并定性。

## 发现

- "Text only" 为**每笔记视图模式**：选项菜单切换 → 隐藏非文本
  元素优化阅读 → `isTextOnly`（可空 INTEGER）按笔记持久化。
- UX 链完整：on/off 横幅 + notice 提示 + Dismiss +
  `auto_exit`（"Showing the full note"——加入非文本内容时自动退出）。
- 21 个文件触及；读写为按笔记 `SELECT/UPDATE NoteStateEntity`。
- Harmony `NoteViewState` 无对应字段——纯版本差。

## 分类

ADR-0717 登记为**版本差·本地候选**（无后端依赖）。采纳与否属
产品决策——回移需状态列 + 隐藏排版路径 + 横幅 UX，独立 Phase
另行判定；本阶段仅固化规格。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
