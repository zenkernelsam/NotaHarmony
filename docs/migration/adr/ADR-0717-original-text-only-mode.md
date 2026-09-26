# ADR-0717 — 原版 1.4.2 文本专属模式登记为本地候选版本差

日期：2026-09-29
状态：已登记（版本差·本地候选；**本阶段不实现**）
证据：`docs/migration/evidence/phase-773-original-text-only-mode.md`
Replay：`docs/migration/replays/d02-original-text-only-mode.mjs`
上游：ADR-0708、ADR-0711（NoteStateEntity.isTextOnly 列增量）

## 背景

`isTextOnly`（Phase 767 列增量）经查为完整功能：1.4.2 在笔记选项
菜单提供 "Text only" 切换，开启后隐藏非文本元素优化阅读；
`NoteStateEntity.isTextOnly` 可空列持久化；三态横幅（on/off/
notice）+ 加入非文本内容时自动退出（"Showing the full note"）。
21 个文件触及该字段。

## 决策

登记为**版本差·本地候选**——纯本地特性（无后端依赖），但：

1. 移植基线为 1.0.3（ADR-0708），1.4.2 功能不自动进入范围；
2. 采纳与否是产品决策：回移需新增 isTextOnly 状态列 +
   非文本元素隐藏排版路径 + 横幅/自动退出 UX，工作量独立成 Phase；
3. 本阶段仅固化语义证据，为 T-042 与潜在回移 Phase 提供规格。

## 后果

- Replay 钉住持久化语句、迁移列与文案链。
- 若未来回移：语义规格为"隐藏非文本元素 + 三态横幅 +
  非文本内容触发自动退出"。
