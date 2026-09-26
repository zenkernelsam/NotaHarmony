# ADR-0718 — 原版 1.4.2 画廊社区产品面整体维持 fail-closed

日期：2026-09-29
状态：已登记（版本差·后端边界，维持 ADR-0708；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-774-original-gallery-surface.md`
Replay：`docs/migration/replays/d02-original-gallery-surface.mjs`
上游：ADR-0708、ADR-0710（outbox schema）

## 背景

`feature_library_gallery__*` 字符串族共 131 键，构成完整社区产品：
发布→审核队列（awaiting_review/quarantined）→发现/搜索→互动
（like/comment/follow）→remix 谱系→收藏集+举报五分类+资料页，
邮箱验证为发布前置。本地侧仅 Phase 766 的 outbox 双表。

## 决策

整体维持 **fail-closed**：全子面均依赖 GingerLabs 画廊后端 +
审核基础设施 + 账号体系。不移植、不伪造、不做"本地画廊"壳。

## 后果

- 131 键族规模与子面划分归档为 T-042 输入。
- 画廊入口在 Harmony 侧保持未暴露状态。
