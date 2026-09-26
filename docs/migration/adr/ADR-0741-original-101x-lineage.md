# ADR-0741 — 原版 1.0.x 线内差与三版谱系登记

日期：2026-09-29
状态：已登记（谱系事实 + 线内差归属；无源码变更）
证据：`docs/migration/evidence/phase-797-original-101x-lineage.md`
Replay：`docs/migration/replays/d02-original-101x-lineage.mjs`

## 背景

decompiled_1.0.1 存在（vc1001）；三版谱系为
1.0.1→1.0.3→1.4.2。补齐 1.0.x 线内差归属。

## 决策

- 1.0.1→1.0.3 差全部归后端绑定簇：账户删除状态机 +
  logout 同步态 + paywall 文案重构——Harmony 本地优先
  无账户面，随登录/订阅 fail-closed 簇登记。
- 类面无新增 gingerlabs 包；资产仅 dexopt 重建。
- 结论：1.0.3 作为本地行为移植基线的代表性获证——
  线内差无本地功能面。

## 后果

- 三版谱系（1001/1014/1040002）入册为 T-042 输入。
- 移植基线置信度提升：1.0.x 线内无遗漏本地面。
