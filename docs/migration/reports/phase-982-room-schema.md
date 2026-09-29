# Phase 982 报告 — Room/SQLite schema 全枚举

## 范围

wp1/iq1/y93/ip1/na4 五个 DAO 绑定器（ba8/ukc =
WorkManager 库表除外）。纯审计。

## 原版发现

- **18 张应用表**：同步 7 + 学习 4 + 文件夹客户端 2 +
  笔记状态/纸张 5。
- 双轨同步模型：`Client*` 写队列（idempotencyKey）
  vs `Synced*Metadata` 基线（checksum 指纹列）。
- `NoteStateEntity` 持久化 zoom/scrollOffset/
  zoomViewShown/lastCodeBlockLanguage UI 态。
- `PaperBackground`/`BackgroundInfo` = 本地纸张偏好
  （与线型 paper 解耦）。

## 产出

- 证据：`phase-982-room-schema.md`
- Fixture：`d02-room-schema.mjs`（25/25）
- ADR-0926；全量 Replay 见本提交。
