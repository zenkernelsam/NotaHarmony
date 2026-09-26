# ADR-0733 — 原版 1.4.2 模板管理器面与分享面板差登记

日期：2026-09-29
状态：已登记（版本差·本地候选 + 已对齐面；无源码变更）
证据：`docs/migration/evidence/phase-789-original-templates-share.md`
Replay：`docs/migration/replays/d02-original-templates-share.mjs`
上游：ADR-0708、ADR-0726、Phase 674、Phase 764

## 背景

`ui_templates__` 由 1.0.3 选择器扩为 1.4.2 完整管理器：
interactive 语义钉（可编辑对象 vs 背景图）、页签/空态、
导入/编辑/删除不伤既有笔记；`ui_share__` 主体已对齐
（Phase 674），新增仅 gallery_* 发布段。

## 决策

1. **模板管理器（含 interactive 语义）**：版本差·本地候选——
   自建模板 CRUD 无后端依赖。
2. **gallery_* 发布段**：随 Phase 774 后端边界。
3. 分享面板五格式：已对齐，无动作。
4. 本阶段不实现。

## 后果

- Phase 764 `interactive` 列语义闭环（editable ↔ background）。
- `ui_templates__`/`ui_share__` 差集归属完毕。
