# Phase 800 — 原版组件面→Harmony Ability 映射表

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-800-original-component-map.md`
ADR：`ADR-0744-original-component-map.md`
Replay：`d02-original-component-map.mjs`（6/6）

## 本阶段做了什么

manifest 组件面逐项映射收尾：Activity/Service/Provider/
Receiver/Initializer 五类全量归属。

## 发现

- Activity 面两版零差（6 个 app Activity 逐名一致）。
- Widget 五 Provider + 图片 Provider → NoteFormAbility
  + 三卡片页闭环。
- MissingNativeLibraryActivity 登记 Android-only
  （HAP 安装期校验原生库）。
- 服务/Provider/Receiver/Initializer 各归既有簇。

## 验收

- Replay 6/6 绿；manifest 组件面闭合；全量套件与双 HAP
  随本阶段执行。
