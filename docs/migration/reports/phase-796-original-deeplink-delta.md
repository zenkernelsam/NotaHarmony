# Phase 796 — 原版 1.4.2 深链与 intent-filter 差

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-796-original-deeplink-delta.md`
ADR：`ADR-0740-original-deeplink-delta.md`
Replay：`d02-original-deeplink-delta.mjs`（6/6）

## 本阶段做了什么

diff 两版 AndroidManifest intent-filter，完成深链面归属。

## 发现

- 1.4.2 新增两条深链：`/gallery` pathPrefix（774 画廊簇）
  与 `/event/planner2627[/]`（782 计划本营销簇）。
- 其余链路两版一致：authlink/app.note/plus25/learn-from-
  home/msauth/PDF VIEW·SEND/CREATE_NOTE。
- manifest 内 `HwrEngineService` 声明佐证 768 本地服务。
- Harmony DeepLinkIngress 已处理 notability.com/app.note；
  /event/* 营销族与 gallery 均登记 fail-closed。

## 验收

- Replay 6/6 绿；manifest 面闭合；全量套件与双 HAP
  随本阶段执行。
