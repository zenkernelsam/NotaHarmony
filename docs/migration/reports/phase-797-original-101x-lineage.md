# Phase 797 — 原版 1.0.x 线内差与三版谱系注册

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-797-original-101x-lineage.md`
ADR：`ADR-0741-original-101x-lineage.md`
Replay：`d02-original-101x-lineage.mjs`（6/6）

## 本阶段做了什么

发现并利用 decompiled_1.0.1，完成 1.0.1→1.0.3 线内差
归属与三版谱系注册。

## 发现

- 谱系：1.0.1(vc1001) → 1.0.3(vc1014) → 1.4.2(vc1040002)。
- 线内差 +21 键：账户删除状态机（confirm/error/
  in_progress/sync_failed）+ logout 同步态（syncing/
  synced/sync_failed/unsynced/countdown/sync_now）+
  paywall 文案重构。
- 线内差全部后端绑定；无本地功能面差——1.0.3 基线
  代表性获证。
- 无新 gingerlabs 包；assets 仅 dexopt 重建。

## 验收

- Replay 6/6 绿；全量套件与双 HAP 随本阶段执行。
